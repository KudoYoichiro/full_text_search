require './he_core'

DocsDir.new.remove_space_from_dirname
CgiDir.new.synchronize_with_docs_dir
CasketDir.new.purge_casket_dirs
IniDir.new.create_ini_files
if ARGV.index("-i")
	IniDir.new.create_index
end
GlobalMenu.new.create
IndexPage.new.create