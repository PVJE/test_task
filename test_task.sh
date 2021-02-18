#!/bin/bash

if [ "$#" -ne 2 ]; then
	echo "Illegal number of parameters (example: sudo ./script.sh ansible or terrafrom and aws_region)"
	exit 1
fi

until [[ -z "$dockerimage" || "$dockerimage" =~ ^[a|t][n|e][s|r][i|r][b|a][l|f][e|o] ]]; do
        echo "$dockerimage: incorrect variable (ansible|terraform only)"
        exit 1
done
#simple check if user forgot to add user to docker group
if [[ "$EUID" -ne 0 ]]; then
        echo "You need to run this as root"
        exit 1
fi
#Dynamic variables
dockerimage=$1
aws_profile=$2

#Static variables
ansible_version="2.9"
awscli_version="1.18.19"
terraform_version="0.14.0"
dfn="Dockerfile"
andir="ansible"
tfdir="terraform"



if [[ $dockerimage = 'ansible' ]]; then
	echo "build $dockerimage image"

mkdir -p ./"$andir"

> ./"$andir"/"$dfn"

        cat << EOF > ./"$andir"/"$dfn"
FROM ubuntu:latest

LABEL ansible_version='$ansible_version'
LABEL aws_cli_version='$awscli_version'


ARG AWS_PROFILE

ENV AWSCLI_VERSION='$awscli_version'

# install tools

RUN apt-get update \\
    && apt-get install -y ansible  \\
    && apt-get install -y python3-pip \\
    && pip3 install --upgrade setuptools \\
    && pip3 install --upgrade awscli=='$awscli_version'

RUN apt-get clean && \\
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# add simple host

RUN mkdir /ansible && \
    mkdir -p /etc/ansible && \
    echo "localhost" > /etc/ansible/hosts

WORKDIR /ansible

CMD ["ansible-playbook", "--version"]

EOF

docker build  ./ansible -t ansible-aws-cli \
	--build-arg AWS_PROFILE=$aws_profile \

# add alias to bashrc profile

echo "alias an='docker run -v$HOME/.aws:/root/.aws:ro \
            -v /home/root/.ssh:/home/root/.ssh \
	    -v /home/root/ansible:/ansible
            -it --rm ansible-aws-cli ansible'" >> ~/.bashrc

echo "alias anpl='docker run -v$HOME/.aws:/root/.aws:ro \
            -v /home/root/.ssh:/home/root/.ssh \
            -it --rm ansible-aws-cli ansible-playbook'" >> ~/.bashrc


fi




if [[ $dockerimage = 'terraform' ]]; then
	echo "build $dockerimage image"

mkdir -p ./"$tfdir"

> ./"$tfdir"/"$dfn"

	cat << EOF > ./"$trdir"/"$dfn"
FROM ubuntu:latest
ENV TERRAFORM_VERSION="$terrafrom_version"
ARG AWS_PROFILE

RUN apt-get update -y && \\
# Install Unzip
apt-get install unzip -y && \\
# need wget
apt-get install wget -y 

################################
# Install Terraform
################################

# Download terraform for linux
RUN wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \\
    unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip  -d /usr/bin && \\
    rm -rf /tmp/* && \\ 
    rm -rf /var/cache/apt/* && \\
    rm -rf /var/tmp/*



CMD ["terraform", "--version"]
EOF

docker build ./"$trdir" -t terraform-aws \
	        --build-arg AWS_PROFILE=$aws_profile \

#add alias to bashrc profile

echo "alias trinit='docker run -v$HOME/.aws:/root/.aws:ro \
                    -v /home/root/tr_res:/home/root/tr_res \
		                -it --rm terraform_aws terraform init'"  >> ~/.bashrc

echo "alias trplan='docker run -v$HOME/.aws:/root/.aws:ro \
                    -v /home/root/tr_res:/home/root/tr_res \
		                -it --rm terraform_aws terraform plan'" >> ~/.bashrc

echo "alias trapply='docker run -v$HOME/.aws:/root/.aws:ro \
                    -v /home/root/tr_res:/home/root/tr_res \
                                -it --rm terraform_aws terraform apply'" >> ~/.bashrc

fi

echo "Last step, you need to source ~/.bashrc"
