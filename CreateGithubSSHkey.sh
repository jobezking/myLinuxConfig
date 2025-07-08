cd $HOME/.ssh
rm id_rsa*
ssh-keygen -t ed25519 -C "your_email@example.com" -f $HOME/.ssh/id_ed25519 -q -P ""
cat id_ed25519.pub
#copy contents, go to https://github.com/settings/keys and press New SSH key and paste
ssh -vT git@github.com
# if it works then cd to location where github repository was locally cloned
git remote set-url origin git@github.com:username/your-repository.git
#create a temporary file or edit README.md
git add -A
git commit -am "Update README.md"
git push
