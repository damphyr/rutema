<specification name="TR002">
<title>Migration v0.9 to v1.0</title>
<description>Test that the database migration code is succesfull between versions 0.9.0 and 1.0.0</description>
<scenario>
	<command cmd="cp data/sample09.db data/test.db"/>
	<command cmd="rutema_upgrader data/migration.rutema"/>
	<command cmd="rm data/test.db"/>
</scenario>
</specification>