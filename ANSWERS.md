1 - Escolhi uma estrutua robusta e simples para exemplificar meu conhecimento na AWS. Irei propor uma estrutura utilizando EKS, ECR e CodeBuild, confirme o documento "Diagrama.pdf" no diretório "images".

========
ATENÇÃO!!!
Por se tratar de uma estrutura EKS haverá uma pequena cobrança. Cerca de 0,10 USD por hora. Sendo assim não se esqueça de executar um "terraform destroy" após a avaliçaõ.
========

Para começarmos é importante que o comando aws-cli já esteja devidamente configurado na máquina para o Terraform possa ser utilizado. Vamos lá.

* Acesse o diretório "pre_IaC" e execute os comandos "terraform plan && terraform apply" sem aspas.
    O único objetivo dessa primeira IaC será criar um bucket no S3 o qual será responsável por armazenar o arquivo terraform.tfstate, dessa forma centralizando o arquivo e evitando problemas caso venhams a trabalhar com mais de um pessoa mexendo no código do Terraform.

* Acesse o diretório "IaC" e execute os comandos "terraform plan && terraform apply" sem aspas.
    Agora iremos criar toda a estrutura na AWS, desde a VPC, subnets, regras de segurança e etc.
    Para facilitar e exemplificar a forma que gosto de trabalhar com váriaveis, deixei um arquivo chamado "terraform.tfvars". Isso nos da o poder de mudar configurações de forma rápida e prática sem a necessidade de ficar lendo, relendo e mexendo no código dos manifestos; Dessa forma evitando erros humanos por digitação incorreta.
    OBS: Não recomendo que mudem as seguintes váriaveis repo_url e vpc_cidr_block. A mudança dessa váriaveis pode quebrar a forma com que a estrutura irá funcionar.
    OBS 2: Não recomendo que mudem as configurações de tipo de instâncias, para evitar cobranças indesejadas.

* Com a estrutura criada acesse o console da aws, vá no CodeBuild e acesse o projeto "ninja-codebuild"
* Inicie uma build manualmente.
    Durante o build o teste da aplicaçao em GO será realizado, conforme print "test_codebuild.png" no diretório "Images"
    Caso haja alguma falha no test, o build irá parar de executar sem prosseguir com nenhum outra ação.
    Caso nenhum erro ocorra o processo irá seguir, uma imagem do docker será criada setando algumas váriaveis de ambiente o qual irei explicar mais a frente.

* Configure o kubectl com o seguinte comando "aws eks update-kubeconfig --name ninja_is_alive --region us-east-1" sem aspas.
    OBS: Cuidado, faça um backup das configurações atuais seu kubectl

* Posteriormente será necessário coletar a URL da imagem para configurar no docker. Execute os seguintes comandos.
    infos=$(aws ecr describe-images --repository-name ecrninja  --region us-east-1 --image-ids imageTag=latest | jq .imageDetails[0])
    _id=$(echo ${infos}| jq .registryId | sed 's/"//g')
    _tag=$(echo ${infos}| jq .imageTags[0] | sed 's/"//g')
    url="${_id}.dkr.ecr.us-east-1.amazonaws.com/ecrninja:${_tag}"
    curl -ks https://raw.githubusercontent.com/luciano340/devops_test/master/k8s/deploy.yml |sed "s#PdockerimgP#${url}#" | kubectl apply -f -
    curl -ks https://raw.githubusercontent.com/luciano340/devops_test/master/k8s/hpa.yml | kubectl apply -f -

    Com esses comandos executados você já poderá visualizar a estrutura do k8s. É importante que pegue a URL do LB gerado pela AWS, você pode fazer isso com o comando "kubectl get svc"
    Pega a informação da coluna "external IP".
    É necessário aguardar cerca de 5 minutos para que o link esteja funcional.
    
    Em quanto espera o link funcionar, veja o hpa com o commando "kubectl get hpa"

Feito isso, a infraestrutura está totalmente completa e disponível para testes. Note que configure de uma forma que haja uma escala automática dos PODS e caso venha a ser necessário uma escala automática das instâncias ec2 nos nodes que recebem os pods.

2 - Executar os seguintes comandos:
    * _ecr=$(echo ${url} | cut -d\/ -f1)
    * aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${_ecr}
    * docker pull ${url}
    * docker run -p 8080:8000 ${url}

    Dessa foram você poderá acessar o api através da porta 8080 de seu computador.

    OBS: O dockerfile foi feito com multstage build para otimizar o tamanho da imagem.

3 - Esse fluxo já é realizado através do CodeBuild conforme explicado no passo 1. Também existe a possibilidade de criar um fluxo de teste e fazer a integração com github para que sempre que uma PR seja realizado o teste seja feito e não permita a aprovação de PR caso haja erro no teste.

4 - Para alterar o nome da aplicação primeiramente é importante entender como o código funciona. A função getEnv é a qual devemos focar para a análise, pois a função é responsável por verificar se a variável de embiente repassada no código existe, caso existe irá retornar o valor da variável de ambiente, caso contrário irá retornar o valor que foi previamente passado no momento em que a função escrita. Sendo assim a solução é simples, basta setar uma variável de ambiente no momento da criação da imagem do Docker, consulte o Dockerfile para mais informações.

Verifique a print "curl-desafio4.jpg" no diretório "Images"

5 - Padronizar o fluxo de trabalho com gitflow, para organizar as Branchs, padronização de commits seguindo o conventionalcommits. Sempre manter um ambiente de testes igual ao de produção, sendo que o ambiente de teste poderá ter um Deploy automático. Já no momento de deploys para produção no primieiro momento recomendaria que fosse manual.