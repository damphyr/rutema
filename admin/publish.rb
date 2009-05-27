require 'rubygems'
require 'rake'

$stdout.puts("Generating RDoc")
Dir.chdir("../patir/") {system("rake docs")}
Dir.chdir("../rutema/rutema") {system("rake docs")}
Dir.chdir("../rutema/rutemaweb") {system("rake docs")}
Dir.chdir("../rutema/rutema_elements") {system("rake docs")}
Dir.chdir("../rubot/") {system("rake docs")}

$stdout.puts("Generating filelists")
patir_docs=Rake::FileList['../patir/docu/**/*.html',
  '../patir/docu/**/*.jpg',
  '../patir/docu/**/*.png',
  '../patir/docu/**/*.gif',
  '../patir/docu/**/*.css'
]

rutema_docs=Rake::FileList['../rutema/rutema/docu/**/*.html',
  '../rutema/rutema/docu/**/*.gif',
  '../rutema/rutema/docu/**/*.jpg',
  '../rutema/rutema/docu/**/*.png',
  '../rutema/rutema/docu/**/*.css'
]

rubot_docs=Rake::FileList['../rubot/docu/**/*.html',
  '../rubot/docu/**/*.jpg',
  '../rubot/docu/**/*.png',
  '../patir/docu/**/*.gif',
  '../rubot/docu/**/*.css'
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
FileList["../patir/doc/**/*"].each do |file|
  target=File.dirname(File.join("rubyforge_site/rdoc",file.gsub("../patir/doc/","")))
  if File.stat(file).directory?
  else
    mkdir_p(target,:verbose=>false)
    cp(file,target,:verbose=>false)
  end
end

FileList["../rutema/rutema/doc/**/*"].each do |file|
  target=File.dirname(File.join("rubyforge_site/rutema/rdoc",file.gsub("../rutema/rutema/doc/","")))
  if File.stat(file).directory?
  else
    mkdir_p(target,:verbose=>false)
    cp(file,target,:verbose=>false)
  end
end

FileList["../rutema/rutemaweb/doc/**/*"].each do |file|
  target=File.dirname(File.join("rubyforge_site/rutemaweb/rdoc",file.gsub("../rutema/rutemaweb/doc/","")))
  if File.stat(file).directory?
  else
    mkdir_p(target,:verbose=>false)
    cp(file,target,:verbose=>false)
  end
end

FileList["../rutema/rutema_elements/doc/**/*"].each do |file|
  target=File.dirname(File.join("rubyforge_site/rutema_elements/rdoc",file.gsub("../rutema/rutema_elements/doc/","")))
  if File.stat(file).directory?
  else
    mkdir_p(target,:verbose=>false)
    cp(file,target,:verbose=>false)
  end
end

FileList["../rubot/doc/**/*"].each do |file|
  target=File.dirname(File.join("rubyforge_site/rubot/rdoc",file.gsub("../rubot/doc/","")))
  if File.stat(file).directory?
  else
    mkdir_p(target,:verbose=>false)
    cp(file,target,:verbose=>false)
  end
end
