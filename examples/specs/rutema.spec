<specification name="TR001">
<title>Rutema self hosting test</title>
<description>Test that rutema is usable as a step in a specification using the distro test example</description>
<scenario>
	<command cmd="bundle exec ruby -rubygems -I../../lib ../../bin/rutema -c ../config/minimal.rutema"/>
	<command cmd="bundle exec ruby -rubygems -I../../lib ../../bin/rutema -c ../config/database.rutema"/>
	<command cmd="bundle exec ruby -rubygems  -I../../lib ../../bin/rutema -c ../config/database.rutema ../specs/T001.spec"/>
	<command cmd="bundle exec ruby -rubygems -I../../lib ../../bin/rutema -c ../config/full.rutema"/>
</scenario>
</specification>