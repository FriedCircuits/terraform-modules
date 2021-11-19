# Get Join

Small module that will ssh into a k8s control plan node and run the create join command. This will return a map of info needed to run the join command as well as the full join command.

Intended to be passed to cloud-init of a pre-configured worker node to auto join a cluster.
