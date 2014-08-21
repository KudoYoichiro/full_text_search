require 'socket'
require 'fileutils'

module MyDir
	def traverse_files(path, max_depth=0, original_depth=0, &block)
		if original_depth == 0
			original_depth = path.split(File::SEPARATOR).size
			max_depth += original_depth + 1
		end

		current_depth = path.split(File::SEPARATOR).size

		if current_depth < max_depth
			if File.directory?(path)
				Dir.open(path) do |dir|
					while name = dir.read
						next if name == "."
						next if name == ".."
						traverse_files(File.join(path, name), max_depth, original_depth, &block)
					end
				end
			else
				block.call(path)
			end
		end
	end

	def traverse_dirs(path, max_depth=0, original_depth=0, &block)
		if original_depth == 0
			original_depth = path.split(File::SEPARATOR).size
			max_depth += original_depth
		end

		current_depth = path.split(File::SEPARATOR).size

		if current_depth < max_depth
			if File.directory?(path)
				Dir.open(path) do |dir|
					while name = dir.read
						next if name == "."
						next if name == ".."
						found_path = File.join(path, name)
						if File.directory?(found_path)
							block.call(found_path)
						end
						traverse_dirs(found_path, max_depth, original_depth, &block)
					end
				end
			end
		end
	end

	def create_dir(path)
		begin
			unless File.exist?(path)
				print "creating dir: #{path}..."
				FileUtils.mkdir_p(path)
				print "\e[32mOK\e[m\n"
			end
		rescue Exception => e
			MyErrorHandler.error_message(e)
		end
	end

	def remove_dir(path)
		begin
			if File.exist?(path) && File.directory?(path)
				print "removing dir: #{path}..."
				FileUtils.rm_r(path)
				print "\e[32mOK\e[m\n"
			end
		rescue Exception => e
			MyErrorHandler.error_message(e)
		end
	end

	module_function :traverse_files, :traverse_dirs, :create_dir, :remove_dir
end

module MyErrorHandler
	def error_message(e, terminate=true)
		msg = "#{e.message}"
		e.backtrace.each do |backtrace_line|
			msg += "\n#{backtrace_line}"
		end
		print "\n\e[31mERROR!\e[m #{msg}\n"
		if terminate
			print "program will terminate...\n"
			exit!
		end
	end

	module_function :error_message
end

module MySocket
	def ip_address
			Socket.getifaddrs.select{|x| x.name == "eth0" and x.addr.ipv4?}.first.addr.ip_address
	end

	module_function :ip_address
end
