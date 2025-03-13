multibranchPipelineJob('helm-charts-release') {
    description('Builds a Helm package and releases on GitHub on every push to main')

    branchSources {
        branchSource {
            source {
                github {
                    id('helm-charts-release')
                    credentialsId('github-pat')
                    configuredByUrl(true)
                    repoOwner('cyse7125-sp25-team03')
                    repository('helm-charts')
                    repositoryUrl('https://github.com/cyse7125-sp25-team03/helm-charts.git')
                }
            }
        }
    }

    configure {
        def traits = it / sources / data / 'jenkins.branch.BranchSource' / source / traits
        traits << 'org.jenkinsci.plugins.github__branch__source.BranchDiscoveryTrait' {
            strategyId(1) // Only discover main branch
        }

        // Add push trigger
        it / triggers << 'com.cloudbees.hudson.plugins.folder.computed.PeriodicFolderTrigger' {
                spec('H/5 * * * *')
                interval('300000')
            }   

        // Restrict builds to `main` branch only
        def buildStrategies = it / buildStrategies << 'jenkins.branch.buildstrategies.basic.BranchBuildStrategyImpl' {
            allowedBranches {
                string('main')
            }
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