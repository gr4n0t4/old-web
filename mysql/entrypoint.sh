#!/bin/bash
# Inspired by https://github.com/docker-library/mysql
set -eo pipefail
shopt -s nullglob

# Check if database is initialized
if [ ! -d "/mysql/data/mysql" ]; then

    echo 'Initializing database'
    cd /mysql
    scripts/mysql_install_db --user=mysql
    echo 'Database initialized'

    rootCreate=
    # default root to listen for connections from anywhere
    if [ ! -z "$MYSQL_ROOT_HOST" -a "$MYSQL_ROOT_HOST" != 'localhost' ]; then
        # no, we don't care if read finds a terminating character in this heredoc
        # https://unix.stackexchange.com/questions/265149/why-is-set-o-errexit-breaking-this-read-heredoc-expression/265151#265151
        read -r -d '' rootCreate <<-EOSQL || true
            CREATE USER 'root'@'${MYSQL_ROOT_HOST}' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}' ;
            GRANT ALL ON *.* TO 'root'@'${MYSQL_ROOT_HOST}' WITH GRANT OPTION ;
EOSQL
    fi

    # Start daemon for init purpose
    echo 'Starting server to setup users'
    "bin/mysqld" --skip-networking --basedir=/mysql --datadir=/mysql/data --user=mysql &
    pid="$!"
    mysql=( bin/mysql -uroot )

    # Waiting for daemon to come up
    for i in {30..0}; do
        if echo 'SELECT 1' | "${mysql[@]}" &> /dev/null; then
            break
        fi
        echo '.'
        sleep 1
    done
    if [ "$i" = 0 ]; then
        echo >&2 'MySQL init process failed.'
        exit 1
    fi
    echo 'Startup done'

    echo 'Remove test data'
    ${mysql[@]} <<-EOSQL
                -- What's done in this file shouldn't be replicated
                --  or products like mysql-fabric won't work
                SET @@SESSION.SQL_LOG_BIN=0;

                DELETE FROM mysql.user WHERE user NOT IN ('mysql.sys', 'mysqlxsys', 'root') OR host NOT IN ('localhost') ;
                SET PASSWORD FOR 'root'@'localhost'=PASSWORD('${MYSQL_ROOT_PASSWORD}') ;
                GRANT ALL ON *.* TO 'root'@'localhost' WITH GRANT OPTION ;
                ${rootCreate}
                DROP DATABASE IF EXISTS test ;
                FLUSH PRIVILEGES ;
EOSQL
    echo 'Test data removed'
    echo "Import all databases"
    /mysql/bin/mysql -u root -p$MYSQL_ROOT_PASSWORD < /root/databases.sql
    echo "Databases imported"


    # Init done - kill daemon
    echo "Try to kill $pid"
    if ! kill -s TERM "$pid" || ! wait "$pid"; then
        echo 'killed'
        #echo >&2 'MySQL init process failed.'
        #exit 1
    fi
    echo 'end'
fi

exec "$@"
/mysql/bin/mysqld_safe --user=mysql