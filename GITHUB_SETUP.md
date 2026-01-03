# GitHub Setup Instructions for Unistream

## Step 1: Create a GitHub Repository
1. Go to https://github.com and sign in
2. Click the "+" icon in the top right corner → "New repository"
3. Name your repository (e.g., "unistream")
4. Choose Public or Private
5. **DO NOT** check "Initialize this repository with a README"
6. Click "Create repository"

## Step 2: Add and Commit Your Files

Open Terminal and navigate to your project directory:
```bash
cd "/Volumes/Backup Plus/RICH /unistreamP/frontend/unistream"
```

Add all files to git:
```bash
git add .
```

Commit your changes:
```bash
git commit -m "Initial commit: Unistream iOS app"
```

## Step 3: Connect to GitHub

After creating the repository on GitHub, you'll see a page with setup instructions. 
Copy the repository URL (it will look like: `https://github.com/yourusername/unistream.git`)

Add GitHub as a remote (replace with your actual repository URL):
```bash
git remote add origin https://github.com/yourusername/unistream.git
```

## Step 4: Push to GitHub

Push your code to GitHub:
```bash
git branch -M main
git push -u origin main
```

If you're prompted for credentials:
- **Username**: Your GitHub username
- **Password**: Use a Personal Access Token (not your GitHub password)
  - To create one: GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic) → Generate new token
  - Give it "repo" permissions

## Step 5: Verify

Go to your GitHub repository page and refresh. You should see all your files!

## Future Updates

When you make changes and want to push them:
```bash
git add .
git commit -m "Description of your changes"
git push
```

