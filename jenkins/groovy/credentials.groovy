import jenkins.model.*
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.domains.*
import com.cloudbees.plugins.credentials.impl.*
import java.util.Properties

// Get the Jenkins instance
def jenkinsInstance = Jenkins.getInstance()

// Get the global domain
def domain = Domain.global()

def props = new Properties()
def envFile = new File('/etc/default/jenkins')
if (envFile.exists()) {
    props.load(envFile.newDataInputStream())
} else {
    throw new RuntimeException("/etc/default/jenkins file not found")
}

// GitHub credentials
def github_username = props.getProperty('GITHUB_USERNAME')
def github_token = props.getProperty('GITHUB_TOKEN')
def github_id = props.getProperty('GITHUB_ID')
def github_description = props.getProperty('GITHUB_DESCRIPTION')

// Create the credentials
def github_credentials = new UsernamePasswordCredentialsImpl(
        CredentialsScope.GLOBAL,
        github_id,
        github_description,
        github_username,
        github_token
)

// Add the credentials to the global domain
def github_store = jenkinsInstance.getExtensionList('com.cloudbees.plugins.credentials.SystemCredentialsProvider')[0].getStore()
github_store.addCredentials(domain, github_credentials)

// Docker credentials
def docker_username = props.getProperty('DOCKER_USERNAME')
def docker_token = props.getProperty('DOCKER_TOKEN')
def docker_id = props.getProperty('DOCKER_ID')
def docker_description = props.getProperty('DOCKER_DESCRIPTION')

// Create the credentials
def docker_credentials = new UsernamePasswordCredentialsImpl(
        CredentialsScope.GLOBAL,
        docker_id,
        docker_description,
        docker_username,
        docker_token
)

// Add the credentials to the global domain
def docker_store = jenkinsInstance.getExtensionList('com.cloudbees.plugins.credentials.SystemCredentialsProvider')[0].getStore()
docker_store.addCredentials(domain, docker_credentials)

println "Credentials added successfully!"