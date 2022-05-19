/*
    Jenkins file for building the 'Friends For Health' project
    Author    : Yaron Golan <yaron.golan@intl.att.com>
    Created   : 19-May-2020
    Component : MySql server
*/


//      +-----------------------------
//      |  Hard coded variables.
//      +-----------------------------
String gitRepoUrl   = "https://github.com/Haverim-Larefua/haverim-lerefua-server.git"
def    buildServers = ['Dev': 'dev', 'Prod': 'prod']

//      +-----------------------------
//      |  Jenkins job parameters.
//      +-----------------------------
properties ([
    parameters([
        choice (name: 'TARGET_ENV', choices: 'Dev\nProd', description: "Environment name"),
    ]),
])

String prmTargetEnv = params.TARGET_ENV
String nodeName     = buildServers[prmTargetEnv]


node (nodeName) {
    
    try {

        stage ("Init") {
            banner(env.STAGE_NAME)
            currentBuild.result = 'SUCCESS'

            // Set the build server's name.
            currentBuild.description = "Environment = " + nodeName
        }


        stage ("Source control") {
            banner (env.STAGE_NAME)
            git credentialsId: 'azure_AT_haverim.org.il', url: gitRepoUrl
        }


        stage ("Deploy") {
            banner (env.STAGE_NAME)
            sh "/bin/bash ./scripts/build_docker_mysql.sh"
        }
    }
    catch (Exception ex) {
        errorMessage = ex.getMessage()
        error (String.format("Exception was caught - [%s]", errorMessage))
    }
} // node



@NonCPS
def banner(message) {

    int messageLength      = message.length();
    int MAX_MESSAGE_LENGTH = 100
    String dashesLine = ""
    String messageFormat

    if (messageLength <= MAX_MESSAGE_LENGTH) {
        messageFormat = '\t\t\n%s\n|    %s    |\n%s\n'
        for (int i=0 ; i<messageLength+8 ; i++) {
            dashesLine += "-"
        }
        dashesLine = "+" + dashesLine + "+"
    }
    else {
        messageFormat = '\t\t\n%s\n|    %s\n%s\n'
        dashesLine = "+----"
    }

    message = String.format (messageFormat, dashesLine, message, dashesLine)
    println (message)
}
