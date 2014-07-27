require_relative 'cli/base'

module Bb10Cli
  module Cli
    class App < Base
      class_option :verbose, :type => :boolean, :default => false, :required => false,  :desc => 'Show communication with the BB10 device'
      class_option :address, :type => :string,  :default => '169.254.0.1',              :desc => 'Remote IP of the BB10 device'
      class_option :format,  :type => :string,  :default => 'json',                     :desc => 'Output format', :banner => '(csv|json|short)'

      desc 'info', 'Lists BB10 device information'
      def info
        run_command do |bb|
          response = bb.do_command(:DEVICE_INFO)
          parse_default_response(response)
        end
      end

      desc 'uninstall [PACKAGE_ID]', 'Uninstalls an application'
      def uninstall(package)
        run_command do |bb|
          response = bb.do_command(:UNINSTALL, 'package_id' => package)
          parse_default_response(response)
        end
      end

      desc 'install [BAR]', 'Installs an application from a local BAR file'
      def install(bar)
        run_command do |bb|
          response = bb.do_command(:INSTALL, 'file' => UploadIO.new(bar, 'application/zip', File::basename(bar)))
          parse_default_response(response)
        end
      end

    end
  end
end

require_relative 'cli/lsapps'
require_relative 'cli/lsvolumes'
