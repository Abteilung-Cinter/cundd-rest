#!/usr/bin/env bash

set -o nounset
set -o errexit
set +e

: ${FUNCTIONAL_TESTS="yes"}
: ${UNIT_TESTS="yes"}

: ${typo3DatabaseName="typo3"}
: ${typo3DatabaseHost="127.0.0.1"}
: ${typo3DatabaseUsername="root"}
: ${typo3DatabasePassword="root"}


function get_mysql_client_path {
    if [[ `which mysql > /dev/null` ]]; then
        which mysql;
    elif [[ -x /Applications/MAMP/Library/bin/mysql ]]; then
        echo /Applications/MAMP/Library/bin/mysql;
    else
        return 1;
    fi
}

function check_mysql_credentials {
    `get_mysql_client_path` -u${typo3DatabaseUsername} -p${typo3DatabasePassword} -h${typo3DatabaseHost} -D${typo3DatabaseName} -e "exit" 2> /dev/null;
    if [ $? -ne 0 ]; then
        echo "ERROR: Could not connect to MySQL";
        exit 1;
    fi

    php -r '@mysqli_connect("'${typo3DatabaseHost}'", "'${typo3DatabaseUsername}'", "'${typo3DatabasePassword}'", "'${typo3DatabaseName}'") or die(mysqli_connect_error());';
    if [ $? -ne 0 ]; then
        echo "ERROR: Could not connect to MySQL";
        exit 1;
    fi
}

function init_database {
    # Export database credentials
    export typo3DatabaseName=${typo3DatabaseName};
    export typo3DatabaseHost=${typo3DatabaseHost};
    export typo3DatabaseUsername=${typo3DatabaseUsername};
    export typo3DatabasePassword=${typo3DatabasePassword};
    echo "Connect to database '$typo3DatabaseName' at '$typo3DatabaseHost' using '$typo3DatabaseUsername' '$typo3DatabasePassword'";
}

function init_typo3 {
	local baseDir=`pwd`;
	if [[ ! -x ${TYPO3_PATH_WEB}/bin/phpunit ]]; then
		cd ${TYPO3_PATH_WEB};
		composer install;
		cd ${baseDir};
	fi
}

function init {
    # Test the environment
    if [ -z ${TYPO3_PATH_WEB+x} ]; then
        echo "Please set the TYPO3_PATH_WEB environment variable";
        exit 1;
    elif [[ ! -d ${TYPO3_PATH_WEB} ]]; then
        echo "The defined TYPO3_PATH_WEB does not seem to be a directory";
        exit 1;
    fi;

	init_typo3;
    init_database;
}

function unit_tests {
    if [[ ! -z ${1+x} ]] && [[ -e "$1" ]]; then
        ${TYPO3_PATH_WEB}/bin/phpunit --colors -c ${TYPO3_PATH_WEB}/typo3/sysext/core/Build/UnitTests.xml "$@";
    else
        ${TYPO3_PATH_WEB}/bin/phpunit --colors -c ${TYPO3_PATH_WEB}/typo3/sysext/core/Build/UnitTests.xml ./Tests/Unit "$@";
    fi
}

function functional_tests {
    if [[ ! -z ${1+x} ]] && [[ -e "$1" ]]; then
        ${TYPO3_PATH_WEB}/bin/phpunit --colors -c ${TYPO3_PATH_WEB}/typo3/sysext/core/Build/FunctionalTests.xml "$@";
    else
        ${TYPO3_PATH_WEB}/bin/phpunit --colors -c ${TYPO3_PATH_WEB}/typo3/sysext/core/Build/FunctionalTests.xml ./Tests/Functional "$@";
    fi
}

function main {
    init;
    if [[ "$UNIT_TESTS" == "yes" ]]; then
        echo "Run Unit Tests";
        unit_tests "$@";
    fi

    if [[ "$FUNCTIONAL_TESTS" == "yes" ]]; then
        echo "Run Functional Tests";
        check_mysql_credentials;
        functional_tests "$@";
    fi
}

main $@;
