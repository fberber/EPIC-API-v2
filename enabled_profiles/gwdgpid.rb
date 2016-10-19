require 'epic_debugger.rb'
require 'src/epic_resource.rb'
require 'src/epic_profile'

module EPIC

 class Gwdgpid < Profile
      def to_rackful
        {
          'Description' => 'This profile provides support for sharing a prefix between multiple institutes',
        }
      end

      def self.create( request, prefix, suffix, values )
        self.checkUserEntry(request)
        # We can trust in the existance of a Institute code in the config. Now we create local variables.
        username = request.env['REMOTE_USER']
        institute_code = USERS[request.env['REMOTE_USER']][:institute].upcase

        # Enforce the Inst-Recod with an own method
        values = self.enforce_inst_record(values, institute_code)
        # self.debug_dump_values(values)
        values
      end

      def self.update( request, prefix, suffix, old_values, new_values )
        self.checkUserEntry(request)
        username = request.env['REMOTE_USER']
        institute_code = USERS[request.env['REMOTE_USER']][:institute].upcase
        # The PID is enforced in the new values
        new_values = self.enforce_inst_record(new_values, institute_code)
        # Check if the supplied Inst-Code stored for the user is identical to the Inst-Code of the handle-vaalue that is selected for update
        inst_check_passed = false
        old_values.each do |old_val|
          # Find INST value in old_values
          if old_val.type.upcase == 'INST'
            # find INST value in the new_values
            new_values.each do |new_val|
              if new_val.type.upcase == 'INST'
                # The Check is only passed if the INST-fields of the old_val and new_val are identical
                if new_val.data.upcase == old_val.data.upcase
                  inst_check_passed = true
                  break
                end
              end
            end
          end
        end
        # React on failed inst_checks
        unless inst_check_passed
          message = "Enforcing GWDGID-Profile. Handle update blocked, as the #{username} requested a handle with a missmatching Institute-Code"
          raise Rackful::HTTP403Forbidden, message
        end
        new_values
      end

      private
    def self.checkUserEntry(request)
    # Check if a insitute code is available in the config
        if USERS[request.env['REMOTE_USER']][:institute].nil?
          message = "Enforcing GWDGID-Profile. No Insitute-Code set for user #{request.env['REMOTE_USER']}. Request blocked with Error 403 - Forbidden."
          raise Rackful::HTTP403Forbidden, message
        end
      end

      def self.enforce_inst_record (values, inst_number)
        # If the submitted a inst_record, then remove it.
        if values.any? { |v| 'INST' === v.type.upcase }
          newvalues = []
          values.each { |value| newvalues << value unless value.type.upcase == 'INST' }
          values = newvalues
        end
        # Now install an own INST-Record given ind inst_number in the handle-value set.
        idx = 2
        idx += 1 while values.any? { |v| idx === v.idx }
        inst_record = HandleValue.new
        inst_record.idx = idx
        inst_record.type = 'INST'
        inst_record.parsed_data = inst_number
        values << inst_record
        values
      end


    end # class GWDGPID < Profile
end
