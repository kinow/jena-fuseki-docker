#!/bin/sh

if [ "$DEBUG" -eq 1 ]
then
    echo "== Environment:"
    env | sort
    echo "== =="
fi

exec java $JAVA_OPTIONS -cp "$FUSEKI_BASE/lib/*:$FUSEKI_BASE/$JAR_NAME" \
     "-Dlog4j.configuration=file:$FUSEKI_BASE/log4j.properties" \
     "org.apache.jena.fuseki.main.cmds.FusekiMainCmd" "$@"
