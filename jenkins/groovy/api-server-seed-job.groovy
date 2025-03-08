multibranchPipelineJob('api-server-validate-and-build') {
    description('Validates a PR or Builds a Docker image and publishes it to DockerHub on every push to main')

    branchSources {
        branchSource {
            source {
                github {
                    id('webapp-build-and-publish')
                    credentialsId('github-pat')
                    configuredByUrl(true)
                    repoOwner('cyse7125-sp25-team03')
                    repository('api-server')
                    repositoryUrl('https://github.com/cyse7125-sp25-team03/api-server.git')
                }
            }
        }
    }

    configure {
        def traits = it / sources / data / 'jenkins.branch.BranchSource' / source / traits
        traits << 'org.jenkinsci.plugins.github__branch__source.BranchDiscoveryTrait' {
            strategyId(1) // Only discover main branch
        }

        traits << 'org.jenkinsci.plugins.github__branch__source.OriginPullRequestDiscoveryTrait' {
            strategyId(1)
        }
        traits << 'org.jenkinsci.plugins.github__branch__source.ForkPullRequestDiscoveryTrait' {
            strategyId(1)
            trust(class: 'org.jenkinsci.plugins.github_branch_source.ForkPullRequestDiscoveryTrait$TrustPermission')
        }
        

        // Add push trigger
        it / triggers << 'com.cloudbees.hudson.plugins.folder.computed.PeriodicFolderTrigger' {
                spec('H/5 * * * *')
                interval('300000')
            }   

        // Restrict builds to `main` branch only
        def buildStrategiesNode = it / buildStrategies 
        
        buildStrategiesNode << 'jenkins.branch.buildstrategies.basic.BranchBuildStrategyImpl' {
            allowedBranches {
                string('main')
            }
        }
        // Enable build strategies for PRs
        buildStrategiesNode << 'jenkins.branch.buildstrategies.basic.ChangeRequestBuildStrategy' {
            ignoreTargetOnlyChanges(true)
            ignoreUntrustedChanges(false)
        }

    }

    factory {
        workflowBranchProjectFactory {
            scriptPath('Jenkinsfile')
        }
    }

    orphanedItemStrategy {
        discardOldItems {
            numToKeep(20)
        }
    }
}