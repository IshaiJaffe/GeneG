cd C:\Uni\GeneG
START "mongodb" RunMongoD.bat
START "redis" C:\bin\redis\redis-server.exe
START "geneg server" Scripts\python GeneG\manage.py runserver 0.0.0.0:81
START "geneg worker" Scripts\python GeneG\manage.py celeryd
START "geneg cron" Scripts\python GeneG\manage.py celerybeat 
