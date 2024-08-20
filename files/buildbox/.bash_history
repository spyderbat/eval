git clone git@github.com:example/build.git 
cd build
make push-container
cd ..
rm -rf build
git clone git@github.com:example/payroll-app.git 
cd payroll-app
make build
make push-container
cd payroll-app
git pull
make push-container
