#! bin/grep
#Checking operating system
RUN echo "Checking operating system"
if [[ "${OS}" == "Darwin" ]]; then 
    echo "Darwin"
if [[ "${OS}" == "Linux" ]]; then
    echo "Linux"
     
  #Verify that python is installed

  RUN echo "Verifying that python is installed"
 if [ ! -f /usr/local/bin/python ]; then
    echo "Python is not installed"

    echo "Downloading and Installing python latest version"
    RUN apt-get update
    RUN apt-get install -y python
    RUN apt-get upgrade -y 

else RUN echo "python is already installed" 
if [[ "${OS}" == "Window" ]]; then

 #Verify that python is installed
  if [ ! -f /usr/local/bin/python]; then
   echo "Python is not installed"
   echo "Downloading and Installing python latest version"
   #RUN curl -L https://www.python.org/ftp/python/3.11.4/python-3.11.4-amd64.exe

   #install python
   RUN python-3.11.4-amd64.exe

  if [[ "${OS}" == "MacOs" ]]; then

    echo "Darwin"






#Verify that python is installed

RUN echo "Verifying that python is installed"
if [ ! -f /usr/local/bin/python ]; then
    echo "Python is not installed"
else #Downloading and Installing python latest version
    echo "Downloading and Installing python latest version"
   



RUN python setup.py

RUN python zones_ea.py