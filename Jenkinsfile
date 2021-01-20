/*
    Jenkins file for building the 'Friends For Health' project
    Author    : Yaron Golan <yaron.golan@intl.att.com>
    Created   : 24-Mar-2020
    Component : Server
*/



//      +-----------------------------
//      |  Hard coded variables.
//      +-----------------------------
String dockerName    = "ffh_server"
String gitRepoUrl    = "https://github.com/Haverim-Larefua/haverim-lerefua-server.git"
def    buildServers  = ['Dev': 'Dev', 'Prod': 'Prod']



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



// +-----------------------------
// |  Global variables.
// +-----------------------------
String dockerVersion




node (nodeName) {
    
    try {

        stage ("Init") {

            banner(env.STAGE_NAME)

            currentBuild.result = 'SUCCESS'

            // Set the build server's name.
            currentBuild.description = "Environment = ${nodeName}"
        }


        
        stage ("Source control") {

            banner (env.STAGE_NAME)

            git credentialsId: 'azure_AT_haverim.org.il', url: gitRepoUrl
        }



        stage ("Compilation") {
            
            banner (env.STAGE_NAME)
            
            // Get the application version
            dockerVersion = sh returnStdout: true, script: """
                jq -r ".version" package.json
            """
            
            // Build the docker image.
            sh """
                docker build . -t ${dockerName}:${dockerVersion}
            """
        }
        
        
        
        stage ("Deploy") {
            
            banner (env.STAGE_NAME)
            
            sh """
                
                ### Remove the old container, if exists.
                containers=\$(docker ps -a | grep ${dockerName} | wc -l)
                if [ \${containers} -eq 1 ]; then
                    docker rm -f ${dockerName}
                fi
                
                
                ### Create a container from the image
                docker create --name ${dockerName} -p 3306:3306 --net=host -e DB_USERNAME=ffh_user -e DB_PASSWORD='ffh_P@ssw0rd' ${dockerName}:${dockerVersion}


                ### Start the container.
                docker start ${dockerName}
            """
        }
    }
    catch (Exception ex) {
        errorMessage = ex.getMessage()
        error (String.format("Exception was caught - [%s]", errorMessage))
    }
} // node






@NonCPS
def banner(message) {

    int MAX_MESSAGE_LENGTH = 100

    int messageLength = message.length();

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




