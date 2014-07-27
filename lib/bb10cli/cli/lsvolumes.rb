require 'csv'
require 'json'

module Bb10Cli
  module Cli
    class App
      desc 'lsvolumes', 'Lists all the mountable volumes on the BB10 device'
      def lsvolumes
        run_command do |bb|
          response = bb.do_command('Status', path: '/cgi-bin/dynamicProperties.cgi', 'Attribute' => 'DeviceVolumes')
          bb_resp = response['RimTabletResponse']['DynamicProperties']

          json = {}

          case bb_resp['Status']
          when 'Success'
            json['volumes'] = {}
            bb_resp['DeviceVolumes']['Volume'].each do |vol|
              json['volumes'][vol['id']] = {
                "StorageType" => vol['StorageType'],
                "ContentType" => vol['ContentType'],
                "Credentials" => vol['SambaConfiguration']['Credentials'],
                "Path"        => vol['SambaConfiguration']['Path']
              }
            end
            json['result'] = 'success'
          else
            json['result'] = 'failure'
          end

          puts JSON.generate(json, JSON_OPTS)
        end
      end
    end
  end
end
