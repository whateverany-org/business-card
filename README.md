# business-card
My first ever PCB, a clone of https://www.thirtythreeforty.net/posts/2019/12/my-business-card-runs-linux. Completely untested, so not sure if it works or not. Build is waiting on on development of my reflow oven https://github.com/whateverany-iot/reflow-oven.

# pcbdraw

## setup env
Create local env secrets and OCI container(s)
```
cp .env.template .env
vi .env
make oci-secrets
# rerun make oci-secrets if any changes to .env
make build
```

## create pcbdraw
```
make pcbdraw
```


### python venv hax
```
      
python3 -m venv .venv

    
```
rm -rf .venv/
python3 -m venv --system-site-packages .venv
source .venv/bin/activate
```
