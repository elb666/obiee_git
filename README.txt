obiee_git

Summary
OBIEE-Git is a package of scripts and tools to assist in getting your OBIEE development under source control.  Written for Bash.

Code Deployment
1. Log into OBIEE host machine as OBIEE user

2. Environment variable MW_HOME must be set.  If it isn't already automatically set in your environment, you can update your .bashrc with something like the following:
  
	export MW_HOME="/app/oracle/biee"

3. Create a Git repository to store your RPD and Catalog.  For convenience the following inializes it one level above MW_HOME:

	cd $MW_HOME/..
	git init my_bi_repo
	
4. Copy or unzip obiee_git directory to $MW_HOME

5. Copy obiee_git/bin/.obieegit and obiee_git/bin/.wl_connect to $MW_HOME and update as noted in each

Using the Scripts
Pre-commit
The pre-commit script precommit.sh converts the current online rpd to a set of xml documents in your Git repository.  Once the conversion is complete, you can use Git commands to commit changes.  Create the initial commit of your RPD by running the pre-commit script.

	$MW_HOME/obiee_git/bin/precommit.sh

Your RPD has been converted to XML in your Git repository, ready for your git add and git commit. From within your Git repo:

	git add -A
	git commit

Deploy
The deploy script deploy.sh converts the set of xml documents in your Git repository to rpd, then deploys that rpd.  Run the deploy script.

	$MW_HOME/obiee_git/bin/deploy.sh

Your RPD has been deployed and you are ready to do development.  
