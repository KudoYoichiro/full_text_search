require './config'
require './my_modules'
require 'fileutils'

class Configuration
	include MyErrorHandler, MyDir

	attr_reader :server_url,
	:server_path,
	:cgi_url,
	:cgi_path,
	:documents_url,
	:documents_path,
	:hyperestraier_filter_path,
	:index_file_path,
	:index_url,
	:logfile_path,
	:caskets_path,
	:ini_path,
	:estseek_master_path,
	:estseek_master_conf_path,
	:estseek_master_cgi_path,
	:estseek_master_help_path,
	:estseek_master_tmpl_path,
	:estseek_master_top_path,
	:conf_settings,
	:index_settings,
	:css_path,
	:javascript_path

	def initialize
		set_paths
		set_conf_params
		set_index_params
	end
end

class BaseDir
	include MyErrorHandler, MyDir

	attr_reader :path

	def initialize(path)
		@path = path
	end

	def exist?
		return File.exist?(@path)
	end

	def name
		return File.basename(@path)
	end

	def create_my_dir
		create_dir(@path)
	end

	def remove_my_dir
		remove_dir(@path)
	end

	def sub_dirs
		ary = Array.new
		traverse_dirs(@path, 1){|path| ary << BaseDir.new(path)}

		return ary
	end
end

class MainCategory < BaseDir
	def initialize(path)
		super(path)
	end

	def sub_categories
		sub_dirs.map{|dir| SubCategory.new(dir.path, self)}.sort{|a, b| a.name <=> b.name}
	end
end

class SubCategory < BaseDir
	attr_reader :main_category

	def initialize(path, main_category)
		super(path)
		@main_category = main_category
	end

	def genres
		sub_dirs{|dir| Genre.new(dir.name, self)}.sort{|a, b| a.name <=> b.name}
	end
end

class Genre < BaseDir
	attr_reader :sub_category

	def initialize(path, sub_category)
		super(path)
		@sub_category = sub_category
	end
end

class DocsDir < BaseDir
	SEPARATOR = "_"

	def initialize
		path = Configuration.new.documents_path
		super(path)
	end

	def main_categories
		sub_dirs.map{|dir| MainCategory.new(dir.path)}.sort{|a, b| a.name <=> b.name}
	end

	def remove_space_from_dirname
		(1..3).each do |i|
			traverse_dirs(@path, i){|path|
				new_path = path.gsub(/\s/, SEPARATOR)
				File.rename(path, new_path)
			}
		end
	end
end

class CgiDir < BaseDir
	def initialize
		path = Configuration.new.cgi_path
		super(path)
	end

	def main_categories
		sub_dirs.map{|dir| CgiMainCategory.new(dir.path)}.sort{|a, b| a.name <=> b.name}
	end

	def synchronize_with_docs_dir
		print "*** synchronize cgi-bin dir ***\n"
		remove_old_main_category_dirs
		create_new_main_category_dirs
	end

	def remove_old_main_category_dirs
		docs_dir = DocsDir.new
		self.main_categories.each do |cgi_main_category|
			docs_main_category = MainCategory.new(File.join(docs_dir.path, cgi_main_category.name))
			if !docs_main_category.exist?
				cgi_main_category.remove_my_dir
			end
		end
	end

	def create_new_main_category_dirs
		docs_dir = DocsDir.new
		docs_dir.main_categories.each do |docs_main_category|
			cgi_main_category = CgiMainCategory.new(File.join(@path, docs_main_category.name))
			if !cgi_main_category.exist?
				cgi_main_category.create_my_dir
			end

			cgi_main_category.remove_cgi_file(docs_main_category)
			cgi_main_category.remove_conf_file(docs_main_category)
			cgi_main_category.create_cgi_file(docs_main_category)
			cgi_main_category.create_conf_file(docs_main_category)
		end
	end
end

class CgiMainCategory < MainCategory
	def initialize(path)
		super(path)
	end

	def get_files(class_name, ext)
		ary = Array.new
		traverse_files(@path, 1) do |path|
			if File.extname(path) == ext
				ary << class_name.new(path, self)
			end
		end

		return ary.sort{|a, b| a.name <=> b.name}
	end

	def cgi_files
		get_files(CgiFile, ".cgi")
	end

	def conf_files
		get_files(ConfFile, ".conf")
	end

	def create_cgi_file(docs_main_category)
		docs_main_category.sub_categories.each do |docs_sub_category|
			cgi = CgiFile.new(File.join(@path, docs_sub_category.name + ".cgi"), self)
			if !cgi.exist?
				cgi.create
			end
		end
	end

	def create_conf_file(docs_main_category)
		docs_main_category.sub_categories.each do |docs_sub_category|
			conf = ConfFile.new(File.join(@path, docs_sub_category.name + ".conf"), self)
			conf.create(docs_sub_category)
		end
	end

	def remove_cgi_file(docs_main_category)
		self.cgi_files.each do |cgi_file|
			docs_cgi = CgiFile.new(File.join(docs_main_category.path, cgi_file.name_without_ext), self)
			if !docs_cgi.exist?
				cgi_file.remove
			end
		end
	end

	def remove_conf_file(docs_main_category)
		self.conf_files.each do |conf_file|
			docs_conf = ConfFile.new(File.join(docs_main_category.path, conf_file.name_without_ext), self)
			if !docs_conf.exist?
				conf_file.remove
			end
		end
	end
end

class BaseFile
	include MyErrorHandler

	attr_reader :path

	def initialize(path)
		@path = path
	end

	def exist?
		return File.exist?(@path)
	end

	def name
		return File.basename(@path)
	end

	def name_without_ext
		return File.basename(@path, File.extname(@path))
	end

	def remove
		begin
			if self.exist?
				print "removing file: #{@path}..."
				File.delete(@path)
				print "\e[32mOK\e[m\n"
			end
		rescue Exception => e
			error_message(e)
		end
	end
end

class CgiFile < BaseFile
	attr_reader :cgi_main_category

	def initialize(path, cgi_main_category)
		super(path)
		@cgi_main_category = cgi_main_category
	end

	def create
		begin
			source = Configuration.new.estseek_master_cgi_path
			FileUtils.copy(source, @path)
		rescue Exception => e
			error_message(3)
		end
	end

	def url
		cgi_url = Configuration.new.cgi_url
		File.join(cgi_url, @cgi_main_category.name, self.name_without_ext + ".cgi")
	end
end

class ConfFile < BaseFile
	attr_reader :cgi_main_category

	SEPARATOR = "{{!}}"

	def initialize(path, cgi_main_category)
		super(path)
		@cgi_main_category = cgi_main_category
	end

	def create(docs_sub_category)
		begin
			source = File.open(Configuration.new.estseek_master_conf_path)

			print "creating file: #{@path}..."

			File.open(@path, "w") do |conf_file|
				source.each_line do |line|
					line.sub!(/^indexname.+$/, indexname_line(docs_sub_category))
					line.sub!(/^replace: \^file.+$/, replace_line)
					line.sub!(/^tmplfile.+$/, tmplfile_line)
					line.sub!(/^topfile.+$/, topfile_line)
					line.sub!(/^helpfile.+$/, helpfile_line)
					line.sub!(/^deftitle.+$/, deftitle_line(docs_sub_category))
					line.sub!(/^condgstep.+$/, condgstep_line)
					line.sub!(/^candir.+$/, candir_line)
					line.sub!(/^formtype.+$/, formtype_line)
					line.sub!(/^logfile.+$/, logfile_line(docs_sub_category))
					conf_file.write(line)
				end
				conf_file.write(genrecheck_line(docs_sub_category))
			end

			print "\e[32mOK\e[m\n"
		rescue Exception => e
			error_message(e)
		ensure
			source.close
		end
	end

	def indexname_line(docs_sub_category)
		str = "indexname:"

		begin
			if docs_sub_category == nil
				raise ArgumentError, "sub_category not defined"
			end

			str += File.join(
				Configuration.new.caskets_path,
				docs_sub_category.main_category.name,
				docs_sub_category.name
				)
		rescue Exception => e
			error_message(e)
		end

		return str
	end

	def replace_line
		str = "replace: "
		str += "^file://"
		str += Configuration.new.documents_path + "/"
		str += SEPARATOR
		str += Configuration.new.documents_url + "/"

		return str
	end

	def tmplfile_line
		"tmplfile: #{Configuration.new.conf_settings[:tmplfile]}"
	end

	def topfile_line
		"topfile: #{Configuration.new.conf_settings[:topfile]}"
	end

	def helpfile_line
		"helpfile: #{Configuration.new.conf_settings[:helpfile]}"
	end

	def deftitle_line(docs_sub_category)
		str = "deftitle: "
		str += Configuration.new.conf_settings[:deftitle]
		if docs_sub_category != nil
			str += docs_sub_category.name
		end

		return str
	end

	def condgstep_line
		"condgstep: #{Configuration.new.conf_settings[:condgstep]}"
	end

	def candir_line
		"candir: #{Configuration.new.conf_settings[:candir]}"
	end

	def formtype_line
		"formtype: #{Configuration.new.conf_settings[:formtype]}"
	end

	def logfile_line(docs_sub_category)
		"logfile: #{Configuration.new.conf_settings[:logfile]}"
	end

	def genrecheck_line(docs_sub_category)
		str = "\n"

		begin
			if docs_sub_category == nil
				raise ArgumentError, "sub_category not defined"
			end
			docs_sub_category.genres.each do |docs_genre|
				str += "genrecheck: #{docs_genre.name}"
				str += SEPARATOR
				str += "#{docs_genre.name}\n"
			end
		rescue Exception => e
			error_message(e)
		end

		return str
	end
end

class CasketDir < BaseDir
	def initialize
		path = Configuration.new.caskets_path
		super(path)
	end

	def main_categories
		sub_dirs.map{|dir| CasketMainCategory.new(dir.path)}.sort{|a, b| a.name <=> b.name}
	end

	def purge_casket_dirs
		print "\n*** purging caskets dir ***\n"
		self.main_categories.each do |casket_main_category|
			docs_main_category_path = File.join(Configuration.new.documents_path, casket_main_category.name)
			docs_main_category = MainCategory.new(docs_main_category_path)
			if !docs_main_category.exist?
				casket_main_category.remove_my_dir
				next
			end

			casket_main_category.sub_categories.each do |casket_sub_category|
				docs_sub_category_path = File.join(docs_main_category.path, casket_sub_category.name)
				docs_sub_category = SubCategory.new(docs_sub_category_path, docs_main_category)
				if !docs_sub_category.exist?
					casket_sub_category.remove_my_dir
				end
			end
		end
	end
end

class CasketMainCategory < MainCategory
	def initialize(path)
		super(path)
	end
end

class IniDir < BaseDir
	def initialize
		path = Configuration.new.ini_path
		super(path)
	end

	def ini_files
		ary = Array.new
		traverse_files(@path, 1){|path| ary << IniFile.new(path)}

		return ary
	end

	def create_ini_files
		purge_ini_files

		DocsDir.new.main_categories.each do |docs_main_category|
			path = File.join(@path, docs_main_category.name + ".ini")
			ini_file = IniFile.new(path)
			ini_file.create(docs_main_category)
		end
	end

	def purge_ini_files
		print "\n*** purging ini dir ***\n"
		ini_files.each do |ini_file|
			docs_main_category_path = File.join(Configuration.new.documents_path, ini_file.name_without_ext)
			docs_main_category = MainCategory.new(docs_main_category_path)
			if !docs_main_category.exist?
				ini_file.remove
			end
		end
	end

	def create_index
		ini_files.each do |ini_file|
			begin
				print "\n*** excuting #{ini_file.name} ***\n"
				sleep(1)
				system(ini_file.path)
			rescue Exception => e
				error_message(e, false)
			end
		end
	end
end

class IniFile < BaseFile
	def initialize(path)
		super(path)
	end

	def create(docs_main_category)
		print "\n#** creating index cmd file ***\n"

		begin
			main_casket_path = File.join(Configuration.new.caskets_path, docs_main_category.name)
			main_casket = CasketMainCategory.new(main_casket_path)
			main_casket.create_my_dir

			print "creating file: #{@path}..."

			File.open(@path, "w") do |file|
				file.write(filter_path)

				docs_main_category.sub_categories.each do |docs_sub_category|
					casket_path = File.join(main_casket.path, docs_sub_category.name)

					file.write("\n#*** create #{docs_sub_category.name} index ***\n")
					file.write(top_line(casket_path))

					docs_sub_category.genres.each do |docs_genre|
						file.write(plane_text_with_genre_cmd(casket_path, docs_genre))
						file.write(msoffice_with_genre_cmd(casket_path, docs_genre))
						file.write(msofficex_with_genre_cmd(casket_path, docs_genre))
						file.write(pdf_with_genre_cmd(casket_path, docs_genre))
						file.write("\n")
					end

					file.write(plane_text_cmd(casket_path, docs_sub_category))
					file.write(msoffice_cmd(casket_path, docs_sub_category))
					file.write(msofficex_cmd(casket_path, docs_sub_category))
					file.write(pdf_cmd(casket_path, docs_sub_category))

					file.write("\n#*** purge #{docs_sub_category.name} index ***\n")
					file.write(purge_cmd(casket_path))
					file.write(optimize_cmd(casket_path))
				end
			end

			FileUtils.chmod(0755, @path)

			print "\e[32mOK\e[m\n"

		rescue Exception => e
			error_message(e)
		end
	end

	def filter_path
		str = "#!/bin/bash\n"
		str += "PATH=$PATH:"
		str += Configuration.new.hyperestraier_filter_path + " ; "
		str += "export PATH\n"

		return str
	end

	def top_line(casket_path)
		"estcmd create -attr @genre str '#{casket_path}'\n"
	end

	def cmd_header
		index_settings = Configuration.new.index_settings
		str = "estcmd gather -cl -sd -cm -il ja "
		str += "-pc #{index_settings[:encoding]} "
		str += "-ic #{index_settings[:encoding]} "
		str += "-lf #{index_settings[:file_size]} "

		return str
	end

	def cmd_footer(casket_path, docs_sub_dir)
		str = "'#{casket_path}' "
		str += "'#{docs_sub_dir.path}'\n"

		return str
	end

	def cmd_genre_footer(casket_path, docs_genre)
		str = "-aa @genre '#{docs_genre.name}' "
		str += cmd_footer(casket_path, docs_genre)

		return str
	end

	def plane_text_cmd(casket_path, docs_sub_category)
		str = cmd_header
		str += cmd_footer(casket_path, docs_sub_category)

		return str
	end

	def msoffice_cmd(casket_path, docs_sub_category)
		str = cmd_header
		str += "-fx \".doc,.xls,.ppt\" \"H@estfxmsotohtml\" -fz "
		str += cmd_footer(casket_path, docs_sub_category)

		return str
	end

	def msofficex_cmd(casket_path, docs_sub_category)
		str = cmd_header
		str += "-fx \".docx,.xlsx,.pptx\" \"H@estfx_ooxml2xml.sh\" -fz "
		str += cmd_footer(casket_path, docs_sub_category)

		return str
	end

	def pdf_cmd(casket_path, docs_sub_category)
		str = cmd_header
		str += "-fx \".pdf\" \"H@estfxpdftohtml\" -fz "
		str += cmd_footer(casket_path, docs_sub_category)

		return str
	end

	def plane_text_with_genre_cmd(casket_path, docs_genre)
		str = cmd_header
		str += cmd_genre_footer(casket_path, docs_genre)

		return str
	end

	def msoffice_with_genre_cmd(casket_path, docs_genre)
		str = cmd_header
		str += "-fx \".doc,.xls,.ppt\" \"H@estfxmsotohtml\" -fz "
		str += cmd_genre_footer(casket_path, docs_genre)

		return str
	end

	def msofficex_with_genre_cmd(casket_path, docs_genre)
		str = cmd_header
		str += "-fx \".docx,.xlsx,.pptx\" \"H@estfx_ooxml2xml.sh\" -fz "
		str += cmd_genre_footer(casket_path, docs_genre)

		return str
	end

	def pdf_with_genre_cmd(casket_path, docs_genre)
		str = cmd_header
		str += "-fx \".pdf\" \"H@estfxpdftohtml\" -fz "
		str += cmd_genre_footer(casket_path, docs_genre)

		return str
	end

	def purge_cmd(casket_path)
		str = ""
		t = Time.now.strftime("%A")
		if t == Configuration.new.index_settings[:purge_day]
			str = "estcmd purge -cl \"#{casket_path}\"\n"
		end

		return str
	end

	def optimize_cmd(casket_path)
		str = ""
		t = Time.now.strftime("%A")
		if t == Configuration.new.index_settings[:optima_day]
			str = "estcmd optimize \"#{casket_path}\"\n"
		end

		return str
	end
end

class CustomeTmpl
	include MyErrorHandler

	def initialize
		@original_file_path = Configuration.new.estseek_master_tmpl_path
		@backup_file_path = @original_file_path + ".bk"
	end

	def backup_tmlp_file
		if !File.exist?(@backup_file_path)
			begin
				FileUtils.cp(@original_file_path, @backup_file_path)
			rescue Exception => e
				error_message(e)
			end
		end
	end

	def create
		print "\n*** making custom template ***\n"
		if !File.exist?(@backup_file_path)
			backup_tmlp_file
		end

		html_str = contents_text
		begin
			File.open(@original_file_path, "w") do |file|
				file.write(html_str)
			end
		rescue Exception => e
			error_message(e)
		end

		print "\e[32mOK\e[m\n"
	end

	def contents_text
		cgi_dir = CgiDir.new

		html_str = ""
		html_str << "<!DOCTYPE html>\n"
		html_str << "<html lang='ja'>\n"
		html_str << "\t<head>\n"
		html_str << "\t\t<meta charset='utf-8'>\n"
		html_str << "\t\t<meta http-equiv='X-UA-Compatible' content='IE=edge'>\n"
		html_str << "\t\t<meta name='viewport' content='width=device-width, initial-scale=1'>\n"
		html_str << "\t\t<title><!--ESTTITLE--></title>\n"
		html_str << "\t\t<link href='#{Configuration.new.css_path}' rel='stylesheet'>\n"
		html_str << "\t\t<script src='https://ajax.googleapis.com/ajax/libs/jquery/1.11.1/jquery.min.js'></script>\n"
		html_str << "\t\t<script src='#{Configuration.new.javascript_path}'></script>\n"
		html_str << "\t</head>\n"
		html_str << "\t<body onload='onloadCheckOff();'>\n"
		html_str << "\t\t<nav class='navbar navbar-default navbar-fixed-top' role='navigation'>\n"
		html_str << "\t\t\t<div class='container-fluid'>\n"
		html_str << "\t\t\t\t<div class='navbar-header'>\n"
		html_str << "\t\t\t\t\t<button type='button' class='navbar-toggle collapsed' data-toggle='collapse' data-target='#main_category_menu'>\n"
		html_str << "\t\t\t\t\t\t<span class='sr-only'>Toggle navigation</span>\n"
		html_str << "\t\t\t\t\t\t<span class='icon-bar'></span>\n"
		html_str << "\t\t\t\t\t\t<span class='icon-bar'></span>\n"
		html_str << "\t\t\t\t\t\t<span class='icon-bar'></span>\n"
		html_str << "\t\t\t\t\t</button>\n"
		html_str << "\t\t\t\t\t<a class='navbar-brand' href='#{Configuration.new.index_url}'>Full Text Search</a>\n"
		html_str << "\t\t\t\t</div>\n"

		html_str << "\t\t\t\t<div class='collapse navbar-collapse' id='main_category_menu'>\n"
		html_str << "\t\t\t\t\t<ul class='nav navbar-nav navbar-left'>\n"
		if !cgi_dir.main_categories.empty?
			cgi_dir.main_categories.each do |cgi_main_category|
				html_str << "\t\t\t\t\t\t<li class='dropdown'>\n"
				html_str << "\t\t\t\t\t\t\t<a href='#' class='dropdown-toggle' data-toggle='dropdown'>#{cgi_main_category.name}<span class='caret'></span></a>\n"
				if !cgi_main_category.cgi_files.empty?
					html_str << "\t\t\t\t\t\t\t<ul class='dropdown-menu' role='menu'>\n"
					cgi_main_category.cgi_files.each do |cgi_file|
						html_str << "\t\t\t\t\t\t\t\t<li><a href='#{cgi_file.url}'>#{cgi_file.name_without_ext}</a></li>\n"
					end
					html_str << "\t\t\t\t\t\t\t</ul>\n"
				end
				html_str << "\t\t\t\t\t\t</li>\n"
			end
			html_str << "\t\t\t\t\t</ul>\t\n"
		end
		html_str << "\t\t\t\t</div\n"
		html_str << "\t\t\t</div>\n"
		html_str << "\t\t</nav>\n"
		html_str << "\t\t<div class='container'>\n"
		html_str << "<!--ESTFORM-->\n"
		html_str << "<!--ESTRESULT-->\n"
		html_str << "\t\t</div>\n"
		html_str << "\t\t<nav class='navbar navbar-default navbar-fixed-bottom' role='navigation'>\n"
		html_str << "\t\t\t<div id='estinfo' class='estinfo'>\n"
		html_str << "\t\t\t\t<div id='info-nav'><!--ESTTITLE--></div>\n"
		html_str <<	"\t\t\t\t<a href='http://fallabs.com/hyperestraier/'>Powerd by Hyper Estraier 1.4.13</a>\n"
		html_str << "\t\t\t</div>\n"	
		html_str << "\t\t</nav>\n"
		html_str << "\t</body>\n"
		html_str << "</html>\n"

		return html_str
	end
end

class IndexPage
	include MyErrorHandler

	def redirect_layout(to)
		html_str = "<!DOCTYPE html>\n"
		html_str += "<html lang='ja'>\n"
		html_str += "<head>\n"
		html_str += "<meta http-equiv='refresh' content='0; URL=#{to}' >\n"
		html_str += "</head>\n"
		html_str += "<body></body>\n"
		html_str += "</html>"

		return html_str
	end

	def create
		print "\n*** making index page ***\n"
		redirect_str = "No libraries";

		cgi_dir = CgiDir.new
		if !cgi_dir.main_categories.empty?
			if !cgi_dir.main_categories[0].cgi_files.empty?
				redirect_url = cgi_dir.main_categories[0].cgi_files[0].url
				redirect_str = redirect_layout(redirect_url)
			end
		end

		index_file_path = Configuration.new.index_file_path
		begin
			File.open(index_file_path, "w") do |file|
				file.write(redirect_str)
			end
		rescue Exception => e
			error_message(e)
		end

		print "\e[32mOK\e[m\n"
	end
end