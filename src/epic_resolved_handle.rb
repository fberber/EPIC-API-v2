# Copyright ©2011-2012 Pieter van Beek <pieterb@sara.nl>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'epic_debugger.rb'
require 'epic_json_response.rb'
require 'epic_collection.rb'
require 'epic_sequel.rb'
require 'epic_hs.rb'
require 'base64'
require 'digest'
require 'time'
require 'json'

# By default, the json gem uses the +Ext+ parser and generator, which uses a
# fast Java implementation. We use the +Pure+ parser and generator, because it
# seems to handle Unicode characters better. This is strange, as these two
# implementations should behave identically.
require 'json/pure'

module EPIC
  class ResolvedHandle < Resource

    # The prefix of this Handle
    # @return [String]
    attr_reader :prefix

    # The suffix of this Handle
    # @return [String]
    attr_reader :suffix

    # The entire handle, {#prefix} <tt>"/"</tt> {#suffix}
    # @return [String]
    def handle
      Debugger.instance.debug("epic_handle.rb:#{__LINE__}:handle")
      "#{prefix}/#{suffix}"
    end

    # The URI-encoded handle as it was received by the server.
    # @return [String]
    attr_reader :handle_encoded

    def initialize path
      super path
      Debugger.instance.debug("epic_handle.rb:#{__LINE__}:initialze")
      unless matches = %r{([\d]+(?:\.[^/]+)*)/([^/]+)\z}.match(path)
        raise "Unexpected path: #{path}"
      end
      @suffix = matches[2].to_path.unescape
      @prefix = matches[1].to_path.unescape
      @handle_encoded = matches[0]
      @values = HS.resolve_handle(self.handle)
    end
    
    # @!attribute values [r]
    # @param dbrows [Array<Hash>] only used by {#initialize}. This is an
    #   implementation detail.
    # @return [ Array<HandleValue> ]

    add_media_type 'application/json'
    add_media_type 'application/x-json'

    # @return [ Array< Hash > ]
    def to_rackful
      @values.sort_by { |v| v.index }.collect {
        |v|
        {
          :idx => v.index,
          :type => v.send(:"getTypeAsString"),
          :data => v.send(:"getDataAsString"),
          :timestamp => Time.at(v.timestamp),
          :ttl_type => v.ttl_type,
          :ttl => ( 0 == v.ttl_type ? v.ttl : Time.at( v.ttl ) ),
          :references => v.references.collect { |ref| ref[:idx].to_s + ':' + ref[:handle] },
          :admin_read => v.send(:"getAdminCanRead"),
          :admin_write => v.send(:"getAdminCanWrite"),
          :public_read => v.send(:"getAnyoneCanRead"),
          :public_write => v.send(:"getAnyoneCanWrite")
        }
      }
    end

    # @return [Boolean]
    # @see Rackful::Resource#empty?
    def empty?
      @values.empty?
    end

    # @return [Time]
    # @see Rackful::Resource#last_modified
    def get_last_modified
      [
        Time.at(
        @values.reduce(0) do
        |memo, value|
        value.timestamp > memo ? value.timestamp : memo
        end
        ),
        false # to indicate that this is _not_ a strong validator.
      ]
    end

    # @return [String]
    # @see Rackful::Resource#etag
    def get_etag
      retval = @values.sort_by do
        |value| value.index
      end.reduce(Digest::MD5.new) do
        |digest, value|
        digest <<
        value.index.inspect <<
        value.type.inspect <<
        value.data.inspect <<
        value.references.inspect <<
        value.ttl.inspect <<
        value.ttl_type.inspect <<
        value.send(:"getAdminCanRead").inspect <<
        value.send(:"getAdminCanWrite").inspect <<
        value.send(:"getAnyoneCanRead").inspect <<
        value.send(:"getAnyoneCanWrite").inspect
      end.to_s
      retval = [ retval ].pack('H*')
       Debugger.instance.debug("epic_handle.rb:#{__LINE__}:Handle.get_etag sent HTTP-etag: " + "'" + Base64.strict_encode64(retval)[0..-3] + "' to client")
       "'" + Base64.strict_encode64(retval)[0..-3] + "'"     
    end
  
  end # class Handle

  class Handle::XHTML < Rackful::XHTML
    def each_nested # :yields: strings
      values = self.resource.to_a
      values.each do
        |value|
        value[:timestamp] = Time.at(value[:timestamp]).utc.xmlschema
        value[:ttl] = ( 0 == value[:ttl_type] ) ?
        value[:ttl].to_s + 's' :
        Time.at(value[:ttl]).utc.xmlschema
        value.delete :ttl_type
        value[:perms] =
        ( value[:admin_read]  ? 'r' : '-' ) +
        ( value[:admin_write] ? 'w' : '-' ) +
        ( value[:pub_read]    ? 'r' : '-' ) +
        ( value[:pub_write]   ? 'w' : '-' )
        value.delete :admin_read
        value.delete :admin_write
        value.delete :pub_read
        value.delete :pub_write
      end
      yield self.serialize values
    end

  end # class Collection::XHTML

  class Handle::JSON < Rackful::JSON
    def each
      yield ::JSON::pretty_generate( self.resource.to_a )
    end

  end # class Handle::JSON

end # module EPIC
