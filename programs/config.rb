require './my_modules'

class Configuration
	def set_paths


		@server_url =					"http://#{MySocket.ip_address}"
		@server_path =					"/home/kudo/server_contents"
		@cgi_url = 						File.join("http://#{MySocket.ip_address}/cgi-bin", "fts")
		@cgi_path = 					File.join("/usr/lib/cgi-bin", "fts")
		@documents_url =				File.join(@server_url, "databank/documents")
		@documents_path =				File.join(@server_path, "databank/documents")
		@hyperestraier_filter_path =	"/usr/share/hyperestraier/filter"
		@index_file_path =				File.join(@server_path, "app/full_text_search/index.html")
		@index_url =					File.join(@server_url, "app/captured/index.html")
		@logfile_path =					File.join(@server_path, "app/full_text_search/logfile/")
		@caskets_path =					File.join(@server_path, "app/full_text_search/caskets")
		@ini_path =						File.join(@server_path, "app/full_text_search/ini")
		@estseek_master_path =			File.join(@server_path, "app/full_text_search/estseek_master")
		@estseek_master_conf_path =		File.join(@estseek_master_path, "estseek.conf")
		@estseek_master_cgi_path =		File.join(@estseek_master_path, "estseek.cgi")
		@estseek_master_help_path =		File.join(@estseek_master_path, "estseek.help")
		@estseek_master_tmpl_path =		File.join(@estseek_master_path, "estseek.tmpl")
		@estseek_master_top_path =		File.join(@estseek_master_path, "estseek.top")
		@css_path = 					"/app/captured/assets/css/fts.css"
		@javascript_path = 				"/app/captured/assets/js/fts.js"


	end

	def set_conf_params
		@conf_settings = {


			tmplfile: 	@estseek_master_tmpl_path,
			topfile: 	@estseek_master_top_path,
			helpfile: 	@estseek_master_help_path,
			logfile: 	@logfile_path,
			deftitle: 	"",
			formtype: 	"file",
			condgstep: 	"1",
			candir: 	"true",


		}
	end

	def set_index_params
		@index_settings = {


			file_size: 		1000,
			encoding: 		"UTF-8",
			purge_day: 		Time.now.strftime("%A"),
			optimize_day: 	"Saturday",


		}
	end
end