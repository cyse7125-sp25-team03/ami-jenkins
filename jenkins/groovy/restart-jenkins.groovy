import jenkins.model.Jenkins

Thread.start {
    sleep(30000)
    println("Restarting Jenkins...")
    Jenkins.instance.safeRestart()
}