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
    "ws-cleanup",
    "github-checks"
]

def pluginManager = instance.getPluginManager()
def updateCenter = instance.getUpdateCenter()

def uc = instance.updateCenter
uc.updateAllSites() // Refresh update center metadata

// Track if we need a restart
def needsRestart = false

plugins.each { pluginId ->
    if (!instance.pluginManager.getPlugin(pluginId)) {
        println "Installing ${pluginId}..."
        def plugin = uc.getPlugin(pluginId)
        if (plugin) {
            def installFuture = plugin.deploy()
            while (!installFuture.isDone()) {
                Thread.sleep(1000)
            }
            def result = installFuture.get()
            println "${pluginId} install result: ${result}"
            needsRestart = true
        }
    }
}

instance.save()

// If plugins were installed, restart Jenkins
if (needsRestart) {
    println "Restarting Jenkins to complete plugin installation..."
    instance.restart()
} else {
    // Only try to configure JCasC if no restart is needed
    Thread.start {
        println "Waiting for Jenkins to be fully initialized before applying JCasC..."
        
        // Wait for plugins to be loaded
        while (Jenkins.get().pluginManager == null) {
            sleep(5000)
        }
        
        // Additional wait to ensure plugin is fully initialized
        sleep(10000)

        println "Jenkins is initialized. Loading JCasC..."

        try {
            def jenkinsInstance = Jenkins.get()
            def cascPlugin = jenkinsInstance.pluginManager.getPlugin("configuration-as-code")

            if (cascPlugin == null) {
                println "ERROR: JCasC plugin not installed!"
                return
            }

            // Load JCasC Configuration
            def cascClass = Class.forName("io.jenkins.plugins.casc.ConfigurationAsCode", true, jenkinsInstance.pluginManager.uberClassLoader)
            def cascInstance = cascClass.getMethod("get").invoke(null)
            cascClass.getMethod("configure").invoke(cascInstance)

            println "JCasC configuration applied successfully!"
        } catch (Exception e) {
            println "Error applying JCasC: ${e.message}"
            e.printStackTrace()
        }
    }
}