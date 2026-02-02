#!/usr/bin/env node

/**
 * Interactive Setup Wizard for vibe_in_vps
 *
 * Guides users through the setup process step-by-step
 * with navigation, progress tracking, and helpful links.
 */

const readline = require('readline');
const { exec } = require('child_process');
const { promisify } = require('util');
const execAsync = promisify(exec);

// ANSI color codes
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  dim: '\x1b[2m',
  cyan: '\x1b[36m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  magenta: '\x1b[35m',
};

// Setup steps
const steps = [
  {
    title: 'Welcome to vibe_in_vps Setup',
    content: `
${colors.bright}Zero-ops deployment for your Dockerized apps${colors.reset}

This wizard will guide you through setting up your VPS deployment pipeline.

${colors.cyan}What you'll set up:${colors.reset}
  • GitHub repository (fork)
  • Hetzner Cloud VPS
  • GitHub Actions CI/CD
  • Optional: healthchecks.io monitoring

${colors.cyan}Time required:${colors.reset} 5-10 minutes

${colors.yellow}Prerequisites:${colors.reset}
  • GitHub account
  • Hetzner Cloud account
  • SSH key pair (we'll help you generate one)

Press ${colors.green}[Next]${colors.reset} to begin!
    `,
  },
  {
    title: 'Step 1: Fork the Repository',
    content: `
${colors.cyan}Fork the vibe_in_vps repository to your GitHub account${colors.reset}

1. Open your browser and go to:
   ${colors.blue}https://github.com/YOUR_USERNAME/vibe_in_vps${colors.reset}

2. Click the ${colors.bright}"Fork"${colors.reset} button in the top-right corner

3. Select your account as the destination

4. Wait for the fork to complete

${colors.green}✓ Checkpoint:${colors.reset} You now have your own copy of the repository

${colors.dim}Tip: You can customize the repository name if you want!${colors.reset}
    `,
  },
  {
    title: 'Step 2: Create Required Accounts',
    content: `
${colors.cyan}Set up accounts for the services you'll need${colors.reset}

${colors.bright}1. GitHub Account${colors.reset} (if you don't have one)
   → https://github.com/signup

${colors.bright}2. Hetzner Cloud Account${colors.reset} ${colors.yellow}(Required)${colors.reset}
   → https://console.hetzner.cloud/
   → Sign up and verify your email
   → Add payment method (you won't be charged yet)

${colors.bright}3. healthchecks.io Account${colors.reset} ${colors.dim}(Optional - for monitoring)${colors.reset}
   → https://healthchecks.io/
   → Free tier includes 20 checks

${colors.green}✓ Checkpoint:${colors.reset} All accounts created and verified
    `,
  },
  {
    title: 'Step 3: Generate SSH Keys',
    content: `
${colors.cyan}Create SSH keys for secure server access${colors.reset}

${colors.bright}Check if you already have SSH keys:${colors.reset}

  ls ~/.ssh/id_ed25519*

${colors.bright}If files exist:${colors.reset} Skip to Step 4
${colors.bright}If no files:${colors.reset} Generate new keys:

  ssh-keygen -t ed25519 -C "your_email@example.com"

${colors.yellow}During generation:${colors.reset}
  • Press Enter to accept default location
  • ${colors.bright}Leave passphrase empty${colors.reset} (just press Enter twice)

${colors.bright}View your public key:${colors.reset}

  cat ~/.ssh/id_ed25519.pub

${colors.green}✓ Checkpoint:${colors.reset} SSH keys generated and displayed

${colors.dim}Note: Keep your private key secret! Never share id_ed25519 (without .pub)${colors.reset}
    `,
  },
  {
    title: 'Step 4: Get API Tokens',
    content: `
${colors.cyan}Collect API tokens from each service${colors.reset}

${colors.bright}Hetzner API Token${colors.reset} ${colors.yellow}(Required)${colors.reset}
1. Go to: https://console.hetzner.cloud/
2. Select your project (or create one)
3. Go to Security → API Tokens
4. Click "Generate API Token"
5. Name: "vibe-vps-deploy"
6. Permissions: ${colors.bright}Read & Write${colors.reset}
7. Copy the token (you won't see it again!)

${colors.bright}healthchecks.io API Key${colors.reset} ${colors.dim}(Optional)${colors.reset}
1. Go to: https://healthchecks.io/projects/
2. Click your project
3. Go to Settings → API Access
4. Copy the API key

${colors.green}✓ Checkpoint:${colors.reset} API tokens copied and ready to paste
    `,
  },
  {
    title: 'Step 5: Configure GitHub Secrets',
    content: `
${colors.cyan}Add secrets to your GitHub repository${colors.reset}

${colors.bright}Navigate to Secrets:${colors.reset}
1. Go to your forked repository on GitHub
2. Click Settings → Secrets and variables → Actions
3. Click "New repository secret" for each:

${colors.bright}Required Secrets (5):${colors.reset}

${colors.yellow}HETZNER_TOKEN${colors.reset}
  Paste your Hetzner API token

${colors.yellow}SSH_PUBLIC_KEY${colors.reset}
  Paste output from: cat ~/.ssh/id_ed25519.pub

${colors.yellow}SSH_PRIVATE_KEY${colors.reset}
  Paste ENTIRE output from: cat ~/.ssh/id_ed25519
  ${colors.dim}(Must include "-----BEGIN" and "-----END" lines)${colors.reset}

${colors.yellow}VPS_USER${colors.reset}
  Type exactly: ${colors.bright}deploy${colors.reset}

${colors.yellow}HEALTHCHECKS_API_KEY${colors.reset}
  Paste your healthchecks.io API key
  ${colors.dim}(or leave empty if not using monitoring)${colors.reset}

${colors.green}✓ Checkpoint:${colors.reset} All 5 secrets added to GitHub
    `,
  },
  {
    title: 'Step 6: Run Infrastructure Workflow',
    content: `
${colors.cyan}Provision your VPS using GitHub Actions${colors.reset}

${colors.bright}Run the workflow:${colors.reset}
1. Go to your repository → Actions tab
2. Click "${colors.bright}Provision Infrastructure${colors.reset}" in left sidebar
3. Click "Run workflow" dropdown (right side)
4. Keep "Branch: main" selected
5. Leave "Destroy infrastructure" ${colors.bright}unchecked${colors.reset}
6. Click green "Run workflow" button

${colors.bright}What happens (4-5 minutes):${colors.reset}
  ${colors.green}✓${colors.reset} Terraform provisions VPS on Hetzner
  ${colors.green}✓${colors.reset} Cloud-init installs Docker
  ${colors.green}✓${colors.reset} Firewall configured
  ${colors.green}✓${colors.reset} Deploy user created

${colors.bright}When complete:${colors.reset}
  • Click on the workflow run
  • Click "Summary"
  • ${colors.yellow}Copy the VPS_HOST IP address${colors.reset}
  • ${colors.yellow}Copy the HEALTHCHECK_PING_URL${colors.reset} (if shown)

${colors.green}✓ Checkpoint:${colors.reset} Infrastructure provisioned successfully
    `,
  },
  {
    title: 'Step 7: Add Deployment Secrets',
    content: `
${colors.cyan}Configure secrets for automatic deployments${colors.reset}

${colors.bright}Add the secrets displayed in the workflow summary:${colors.reset}

1. Go to Settings → Secrets and variables → Actions
2. Click "New repository secret"

${colors.yellow}VPS_HOST${colors.reset}
  Paste the IP address from workflow summary

${colors.yellow}HEALTHCHECK_PING_URL${colors.reset} ${colors.dim}(Optional)${colors.reset}
  Paste the ping URL from workflow summary
  ${colors.dim}(or skip if not using monitoring)${colors.reset}

${colors.green}✓ Checkpoint:${colors.reset} Deployment secrets configured

${colors.bright}Now automatic deployments will work!${colors.reset}
    `,
  },
  {
    title: 'Step 8: Deploy Your Application',
    content: `
${colors.cyan}Trigger your first deployment${colors.reset}

${colors.bright}Push code to deploy:${colors.reset}

  git commit --allow-empty -m "trigger first deployment"
  git push origin main

${colors.bright}Watch the deployment:${colors.reset}
1. Go to Actions → "Deploy to VPS" workflow
2. Click on the running workflow
3. Watch it build and deploy (2-3 minutes)

${colors.bright}What happens:${colors.reset}
  ${colors.green}✓${colors.reset} Builds Docker image
  ${colors.green}✓${colors.reset} Pushes to GitHub Container Registry
  ${colors.green}✓${colors.reset} Deploys to your VPS
  ${colors.green}✓${colors.reset} Pings healthchecks.io (if configured)

${colors.green}✓ Checkpoint:${colors.reset} First deployment complete!
    `,
  },
  {
    title: 'Step 9: Verify Your Deployment',
    content: `
${colors.cyan}Check that your app is running${colors.reset}

${colors.bright}Access your app:${colors.reset}
Open in browser: ${colors.blue}http://YOUR_VPS_IP${colors.reset}

${colors.bright}You should see:${colors.reset}
  {
    "message": "Hello from vibe_in_vps!",
    "timestamp": "...",
    "environment": "production"
  }

${colors.bright}Check health endpoint:${colors.reset}
  ${colors.blue}http://YOUR_VPS_IP/health${colors.reset}

${colors.bright}SSH to your server:${colors.reset}
  ssh deploy@YOUR_VPS_IP

${colors.green}✓ Checkpoint:${colors.reset} App deployed and accessible!
    `,
  },
  {
    title: 'Setup Complete! 🎉',
    content: `
${colors.green}${colors.bright}Congratulations! Your zero-ops deployment is live!${colors.reset}

${colors.cyan}What you've set up:${colors.reset}
  ${colors.green}✓${colors.reset} VPS running on Hetzner (~$7.50/month)
  ${colors.green}✓${colors.reset} Automatic deployments on every push
  ${colors.green}✓${colors.reset} Docker + Docker Compose environment
  ${colors.green}✓${colors.reset} GitHub Deployments tracking
  ${colors.green}✓${colors.reset} Optional uptime monitoring

${colors.cyan}Next steps:${colors.reset}

${colors.bright}1. Deploy your own app${colors.reset}
   → Replace contents of /app directory
   → Ensure Dockerfile exposes port 3000
   → Add /health endpoint
   → git push to deploy!

${colors.bright}2. Customize your infrastructure${colors.reset}
   → Edit infra/terraform/variables.tf
   → Change server type, firewall rules, etc.
   → Re-run Provision Infrastructure workflow

${colors.bright}3. Learn more${colors.reset}
   → ${colors.blue}docs/RUNBOOK.md${colors.reset} - Operations guide
   → ${colors.blue}docs/CONTRIBUTING.md${colors.reset} - Development guide
   → ${colors.blue}CLAUDE.md${colors.reset} - Architecture decisions

${colors.yellow}Need help?${colors.reset}
  • Check docs/SETUP.md for detailed troubleshooting
  • Open an issue on GitHub
  • Review the operations runbook

${colors.bright}Happy deploying! 🚀${colors.reset}
    `,
  },
];

// State
let currentStep = 0;

// Clear screen
function clearScreen() {
  process.stdout.write('\x1Bc');
}

// Display step
function displayStep() {
  clearScreen();

  const step = steps[currentStep];
  const progress = `Step ${currentStep + 1} of ${steps.length}`;

  console.log(`${colors.dim}${'='.repeat(80)}${colors.reset}`);
  console.log(`${colors.bright}${step.title}${colors.reset}`);
  console.log(`${colors.dim}${progress}${colors.reset}`);
  console.log(`${colors.dim}${'='.repeat(80)}${colors.reset}`);
  console.log(step.content);
  console.log(`${colors.dim}${'─'.repeat(80)}${colors.reset}`);

  // Navigation hints
  const nav = [];
  if (currentStep > 0) nav.push(`${colors.blue}[P]revious${colors.reset}`);
  if (currentStep < steps.length - 1) nav.push(`${colors.green}[N]ext${colors.reset}`);
  nav.push(`${colors.yellow}[Q]uit${colors.reset}`);

  console.log(`\n${nav.join('  •  ')}\n`);
}

// Handle input
function handleInput(key) {
  switch (key.toLowerCase()) {
    case 'n':
      if (currentStep < steps.length - 1) {
        currentStep++;
        displayStep();
      }
      break;
    case 'p':
      if (currentStep > 0) {
        currentStep--;
        displayStep();
      }
      break;
    case 'q':
      console.log(`\n${colors.yellow}Setup wizard closed.${colors.reset}`);
      console.log(`${colors.dim}You can restart anytime with: npm run setup-wizard${colors.reset}\n`);
      process.exit(0);
      break;
  }
}

// Setup readline
function setupReadline() {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });

  readline.emitKeypressEvents(process.stdin);

  if (process.stdin.isTTY) {
    process.stdin.setRawMode(true);
  }

  process.stdin.on('keypress', (str, key) => {
    if (key.ctrl && key.name === 'c') {
      console.log(`\n\n${colors.yellow}Setup wizard interrupted.${colors.reset}\n`);
      process.exit(0);
    }

    handleInput(key.name);
  });
}

// Main
function main() {
  clearScreen();
  setupReadline();
  displayStep();
}

main();
