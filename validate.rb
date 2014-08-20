require './he_core'
require './my_modules'

class HEValidation
	def check
		paths_to_check = Array.new
		configuration = Configuration.new

		paths_to_check << configuration.server_path
		paths_to_check << configuration.cgi_path
		paths_to_check << configuration.documents_path
		paths_to_check << configuration.hyperestraier_filter_path
		paths_to_check << configuration.logfile_path
		paths_to_check << configuration.caskets_path
		paths_to_check << configuration.ini_path
		paths_to_check << configuration.estseek_master_path
		paths_to_check << configuration.estseek_master_conf_path
		paths_to_check << configuration.estseek_master_cgi_path
		paths_to_check << configuration.estseek_master_help_path
		paths_to_check << configuration.estseek_master_tmpl_path
		paths_to_check << configuration.estseek_master_top_path

		paths_to_check.each do |path|
			begin
				print "checking #{path}..."
				if !File.exist?(path)
					raise IOError
				end
				print "\e[32mOK\e[m\n"
			rescue Exception => e
				print "\e[31mFAIL\e[m\n"
			end
		end
	end
end

HEValidation.new.check
