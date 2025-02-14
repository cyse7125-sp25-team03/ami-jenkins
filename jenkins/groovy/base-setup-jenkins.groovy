import jenkins.model.*
import hudson.security.*
import jenkins.install.*
import java.util.Properties

// Get the Jenkins instance
def instance = Jenkins.getInstance()

// Load environment variables from the properties file
def props = new Properties()
def envFile = new File('/etc/default/jenkins')
if (envFile.exists()) {
    props.load(envFile.newDataInputStream())
} else {
    throw new RuntimeException("/etc/default/jenkins file not found")
}

def admin_username = props.getProperty('JENKINS_ADMIN_USERNAME')
def admin_password = props.getProperty('JENKINS_ADMIN_PASSWORD')

// Check if the environment variables are set
if (admin_username == null || admin_password == null) {
    throw new RuntimeException("Environment variables JENKINS_ADMIN_USERNAME and/or JENKINS_ADMIN_PASSWORD are not set")
}

// Set up Jenkins security realm and authorization strategy
def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount(admin_username, admin_password)
instance.setSecurityRealm(hudsonRealm)

def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
strategy.setAllowAnonymousRead(false)
instance.setAuthorizationStrategy(strategy)

// Set the Jenkins installation state to RUNNING to skip the setup wizard
def state = instance.getInstallState()
if (state != InstallState.RUNNING) {
    InstallState.INITIAL_SETUP_COMPLETED.initializeState()
}

// Install Plugins
def plugins = [
    "configuration-as-code",
    "credentials",
    "credentials-binding",
    "github-branch-source",
    "job-dsl",
    "workflow-aggregator",
    "terraform",
    "github-pullrequest",
    "docker-workflow",
    "git",
    "github",
    "pipeline-graph-view",
    "pipeline-model-definition",
    "pipeline-stage-view",
    "pipeline-utility-steps",
    "ws-cleanup"
]

def pluginManager = instance.getPluginManager()
def updateCenter = instance.getUpdateCenter()

println("Installing required plugins...")
plugins.each { pluginName ->
    println("Checking if plugin $pluginName is installed...")
    if (!pluginManager.getPlugin(pluginName)) {
        def plugin = updateCenter.getPlugin(pluginName)
        if (plugin) {
            println("Deploying plugin $pluginName...")
            plugin.deploy()
        } else {
            println("Plugin $pluginName not found.")
        }
    }
}

instance.save()
