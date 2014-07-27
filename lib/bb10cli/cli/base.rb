require 'csv'
require 'json'

require 'io/console'
require 'pager'

module Bb10Cli
  module Cli
    class Base < ::Thor
      include Pager

      JSON_OPTS = {indent: ' '*2, object_nl: "\n", array_nl: "\n"}

      protected
      def run_command
        check_args

        begin
          bb = Bb10Protocol.new(ip_address: options[:address], password: get_password, cli: options)
          response = bb.do_login

          page unless options[:verbose]

          status = parse_login_response(response)

          if status[:result] == 'success'
            status = yield(bb)
          end

          print_default_status(status, options[:format]) if status
        rescue Exceptions::AuthenticationError
          puts JSON.generate({result: 'failure', reason: 'Unknown Authentication Error'}, JSON_OPTS) + "\n"
        end
      end

      def get_password
        begin
          STDERR.write 'Password: '
          STDERR.flush
          STDIN.noecho(&:gets).chomp
        ensure
          puts
        end
      end

      def check_args
        case options[:format]
        when 'json'
          nil
        else
          raise Exceptions::OutputFormatNotImplementedError
        end

      end

      def print_default_status(status, format)
        case options[:format]
        when 'json'
          STDOUT.write JSON.generate(status, JSON_OPTS)
        else
          raise Exceptions::OutputFormatNotImplementedError
        end
      end

      def parse_login_response(response)
        status = {}

        case response['RimTabletResponse']['Auth']['Status']
        when 'Success'
          status[:result] = 'success'
        when 'Denied'
          status[:result] = 'failure'
          status[:reason] = 'denied'
          status[:attempts_remaining] = response['RimTabletResponse']['Auth']['RetriesRemaining']
        else
          status[:result] = 'failure'
          status[:reason] = 'unknown'
        end

        status
      end

      def parse_default_response(resp)
        status = {}
        resp.split("\n").each do |line|
          if line =~ /\:\:/
            (key,value) = line.split('::', 2)
            status[key] = value

            if (key == 'result')
              value = value.split(' ', 3)
              status[key]=value[0]
              status['code']=value[1] if value[1]
              status['reason']=value[2] if value[2]
            end
          end
        end
        status
      end
    end
  end
end
