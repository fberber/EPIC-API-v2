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
require 'digest'
require 'epic_debugger.rb'
require 'epic_hs.rb'
require '../config.rb'
#require '../enabled_profiles/calcul.rb'
Dir["/home/fberber/pid_dev/epic_11497/enabled_profiles/*.rb"].each {|file| 
puts "loading ="+file
require file }

module EPIC

class Profile 
    
    def self.get_institute_profiles(prefix) 
      na_prefix = "0.NA/"+prefix
      profile_handle = "11497/ENABLED_PROFILES"
      prefix_values = HS.resolve_handle(profile_handle)
      inst_static_profiles = []
      inst_op_profiles = []
      prefix_values.each{
           |prefix_value|
           the_type =  prefix_value.send(:"getTypeAsString")
           Debugger.instance.debug("epic_profile.rb:#{__LINE__}:TYPES = #{the_type}")
           if the_type == "EPIC_ST_PROFILE"
              the_profile_name = prefix_value.send(:"getDataAsString")
              inst_static_profiles << the_profile_name
           elsif the_type == "EPIC_OP_PROFILE"
              the_profile_name = prefix_value.send(:"getDataAsString")
               puts "EPIC_OP_PROFILE = "+the_profile_name
               Debugger.instance.debug("epic_profile.rb:#{__LINE__}:profile name = #{the_profile_name}")
               inst_op_profiles << self.profiles[the_profile_name.upcase]
           end
        } 
    
       return inst_static_profiles,inst_op_profiles          
    end   
    
    # @api private
    # @return [Hash{ String(prefix) => Hash{ String(name) => Profile } }]
    def self.profiles
      @@profiles ||= {}
    end

    # @api private
    # @return [Hash{ String(name) => Profile }]
    def self.[] name
      self.profiles[name.to_s.downcase]
    end

    def self.load_operation_profiles
               

    end

    def self.inherited childclass
      puts "self.inherited"
      # Only enable profiles that have been marked as active in the config 
      profile_name = childclass.name.split('::').last.downcase
      puts "self.inherited profile_name = #{profile_name}"
      Debugger.instance.debug("epic_profile.rb:#{__LINE__}:CHILDCLASS: #{profile_name}")
      self.profiles[profile_name.upcase] = childclass      
      Debugger.instance.debug("epic_profile.rb:#{__LINE__}:Profile activated: #{profile_name}.")

      # Check if Profile is in config
     # profile_found = false
      #ENFORCED_PROFILES.each do |config_profile_name|
     #   if config_profile_name.upcase == profile_name.upcase
     #     self.profiles[profile_name] = childclass
      #    Debugger.instance.debug("epic_profile.rb:#{__LINE__}:Profile activated: #{profile_name}.")
       #   if profile_name == "nodelete"
        #    NO_DELETE.each do |suffix|
         #     Debugger.instance.debug("epic_profile.rb:#{__LINE__}:Profile: nodelete protects Handles under the Suffix: #{suffix} from being deleted.")
          #  end
          #end
          #break
        #end
      #end
    end

    # This method validates the creation of a new handle.
    #
    # The method can not only veto the creation of a handle, but also allow
    # handle creation, but with modified handle values.
    # @param [Rackful::Request] request
    # @param [String] prefix
    # @param [String] suffix
    # @param [(HandleValue)] values
    # @return [(HandleValue), nil] The (possibly modified) array of
    #   {HandleValue HandleValues} to put in the new {Handle}.
    # @raise [Rackful::HTTPStatus] if creation cannot pass.
    def self.create( request, prefix, suffix, values )
      nil
    end

    # @!method
    # This method validates the update of an existing handle.
    #
    # The method can not only veto the creation of a handle, but also allow
    # handle creation, but with modified handle values.
    # @param request [Rackful::Request]
    # @param prefix [String]
    # @param suffix [String]
    # @param old_values [(HandleValue)]
    # @param new_values [(HandleValue)]
    # @return [(HandleValue), nil] The (possibly modified) array of
    #   {HandleValue HandleValues} to put in the new {Handle}.
    # @raise [Rackful::HTTPStatus] if the update cannot pass.
    def self.update( request, prefix, suffix, old_values, new_values )
      nil
    end

    # This method must validate the deletion of a handle.
    # @param handle [Handle]
    # @return [void]
    # @raise [Rackful::HTTPStatus] if the deletion cannot pass.
    def self.delete( request, prefix, suffix, old_values ); end
      
    def self.debug_dump_values(values)
      values.each do |bin_data|
        puts "IDX: #{bin_data.idx()}"
        puts "TYPE: #{bin_data.type()}"
        puts "DATA: #{bin_data.data()}"
        puts "TIMESTAMP: #{bin_data.timestamp()}"
        puts "TTL_TYPE: #{bin_data.ttl_type()}"
        puts "REFS: #{bin_data.refs()}"
        puts "Admin-Read: #{bin_data.admin_read()}"
        puts "Admin-Write: #{bin_data.admin_write()}"
        puts "Pub-Read: #{bin_data.pub_read()}"
        puts "Pub-Write: #{bin_data.pub_write()}"
        puts "-------------"
      end
    end
      
  end # class Profile

end # module EPIC
