require 'digest'
require 'epic_debugger.rb'
require 'src/epic_hs.rb'
require 'src/epic_profile.rb'

module EPIC
  # A profile that uses UUIDs to guarantee the uniqueness of created Handles.
 class Calcul < Profile
      def to_rackful
        {
          'Description' => 'This profile disables the deletion of all pids that match some regular expression.',
        }
      end

      def self.create( request, prefix, suffix, old_values )
          
          index_list = []
          old_values.each{ |ov| index_list << ov.idx}
          sha_val = Digest::SHA1.digest(index_list.join)
          calc_value = HandleValue.new
          calc_value.idx=index_list.max + 1
          calc_value.type="EPIC_CALCUL_SHA1"
          calc_value.data=sha_val

         return old_values << calc_value
      end

    end # class NoDelete < Profile
end

