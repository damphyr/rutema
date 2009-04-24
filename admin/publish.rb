require 'rubygems'
require 'rake'

$stdout.puts("Generating RDoc")
Dir.chdir("../patir/trunk") {system("rake docs")}
Dir.chdir("../rutema/trunk/rutema") {system("rake docs")}
Dir.chdir("../rutema/trunk/rutemaweb") {system("rake docs")}
Dir.chdir("../rutema/trunk/rutema_elements") {system("rake docs")}
Dir.chdir("../rubot/trunk") {system("rake docs")}

$stdout.puts("Generating filelists")
patir_docs=Rake::FileList['../patir/trunk/docu/**/*.html',
  '../patir/trunk/docu/**/*.jpg',
  '../patir/trunk/docu/**/*.png',
  '../patir/trunk/docu/**/*.gif',
  '../patir/trunk/docu/**/*.css'
]

rutema_docs=Rake::FileList['../rutema/trunk/rutema/docu/**/*.html',
  '../rutema/trunk/rutema/docu/**/*.gif',
  '../rutema/trunk/rutema/docu/**/*.jpg',
  '../rutema/trunk/rutema/docu/**/*.png',
  '../rutema/trunk/rutema/docu/**/*.css'
]

rubot_docs=Rake::FileList['../rubot/trunk/docu/**/*.html',
  '../rubot/trunk/docu/**/*.jpg',
  '../rubot/trunk/docu/**/*.png',
  '../patir/trunk/docu/**/*.gif',
  '../rubot/trunk/docu/**/*.css'
]

$stdout.puts("Removing previous artefacts")
rm_rf("rubyforge_site")
$stdout.puts("Generating drectory structure")
mkdir_p("rubyforge_site/rdoc",:verbose=>false)
mkdir_p("rubyforge_site/rutema/rdoc",:verbose=>false)
mkdir_p("rubyforge_site/rutemaweb/rdoc",:verbose=>false)
mkdir_p("rubyforge_site/rubot/rdoc",:verbose=>false)
$stdout.puts("Copying static files")
cp(patir_docs,"rubyforge_site",:verbose=>false)
cp(rutema_docs,"rubyforge_site/rutema",:verbose=>false)
cp(rubot_docs,"rubyforge_site/rubot",:verbose=>false)

$stdout.puts("Copying RDoc")
FileList["../patir/trunk/doc/**/*"].each do |file|
  target=File.dirname(File.join("rubyforge_site/rdoc",file.gsub("../patir/trunk/doc/","")))
  if File.stat(file).directory?
  else
    mkdir_p(target,:verbose=>false)
    cp(file,target,:verbose=>false)
  end
end

FileList["../rutema/trunk/rutema/doc/**/*"].each do |file|
  target=File.dirname(File.join("rubyforge_site/rutema/rdoc",file.gsub("../rutema/trunk/rutema/doc/","")))
  if File.stat(file).directory?
  else
    mkdir_p(target,:verbose=>false)
    cp(file,target,:verbose=>false)
  end
end

FileList["../rutema/trunk/rutemaweb/doc/**/*"].each do |file|
  target=File.dirname(File.join("rubyforge_site/rutemaweb/rdoc",file.gsub("../rutema/trunk/rutemaweb/doc/","")))
  if File.stat(file).directory?
  else
    mkdir_p(target,:verbose=>false)
    cp(file,target,:verbose=>false)
  end
end

FileList["../rutema/trunk/rutema_elements/doc/**/*"].each do |file|
  target=File.dirname(File.join("rubyforge_site/rutema_elements/rdoc",file.gsub("../rutema/trunk/rutema_elements/doc/","")))
  if File.stat(file).directory?
  else
    mkdir_p(target,:verbose=>false)
    cp(file,target,:verbose=>false)
  end
end

FileList["../rubot/trunk/doc/**/*"].each do |file|
  target=File.dirname(File.join("rubyforge_site/rubot/rdoc",file.gsub("../rubot/trunk/doc/","")))
  if File.stat(file).directory?
  else
    mkdir_p(target,:verbose=>false)
    cp(file,target,:verbose=>false)
  end
end
