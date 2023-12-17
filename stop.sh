#!/bin/bash
# James Chambers - https://jamesachambers.com/minecraft-bedrock-edition-ubuntu-dedicated-server-guide/
# Minecraft Server stop script - primarily called by minecraft service but can be ran manually

# Set path variable
USERPATH="pathvariable"
PathLength=${#USERPATH}
if [[ "$PathLength" -gt 12 ]]; then
  PATH="$USERPATH"
else
  echo "Unable to set path variable.  You likely need to download an updated version of SetupMinecraft.sh from GitHub!"
fi

# Check to make sure we aren't running as root
if [[ $(id -u) = 0 ]]; then
  echo "This script is not meant to be run as root. Please run ./stop.sh as a non-root user, without sudo;  Exiting..."
  exit 1
fi

if [[ "$USER" = "userxname" ]]; then
  SCREEN_CMD="screen"
else 
  SCREEN_CMD="sudo -u userxname screen"
fi

# Check if server is running
if ! $SCREEN_CMD -list | grep -q '\.servername\s'; then
  echo "Server is not currently running!"
  exit 1
fi

# Get an optional custom countdown time (in minutes)
CountdownTime=0
while getopts ":t:" opt; do
  case $opt in
  t)
    case $OPTARG in
    '' | *[!0-9]*)
      echo "Countdown time must be a whole number in minutes."
      exit 1
      ;;
    *)
      CountdownTime=$OPTARG >&2
      ;;
    esac
    ;;
  \?)
    echo "Invalid option: -$OPTARG; countdown time must be a whole number in minutes." >&2
    ;;
  esac
done

# Stop the server
while [[ $CountdownTime -gt 0 ]]; do
  if [[ $CountdownTime -eq 1 ]]; then
    $SCREEN_CMD -Rd servername -X stuff "say Stopping server in 60 seconds...$(printf '\r')"
    echo "Stopping server in 60 seconds..."
    sleep 30
    $SCREEN_CMD -Rd servername -X stuff "say Stopping server in 30 seconds...$(printf '\r')"
    echo "Stopping server in 30 seconds..."
    sleep 20
    $SCREEN_CMD -Rd servername -X stuff "say Stopping server in 10 seconds...$(printf '\r')"
    echo "Stopping server in 10 seconds..."
    sleep 10
    CountdownTime=$((CountdownTime - 1))
  else
    $SCREEN_CMD -Rd servername -X stuff "say Stopping server in $CountdownTime minutes...$(printf '\r')"
    echo "Stopping server in $CountdownTime minutes...$(printf '\r')"
    sleep 60
    CountdownTime=$((CountdownTime - 1))
  fi
  echo "Waiting for $CountdownTime more minutes ..."
done
echo "Stopping Minecraft server ..."
$SCREEN_CMD -Rd servername -X stuff "say Stopping server (stop.sh called)...$(printf '\r')"
$SCREEN_CMD -Rd servername -X stuff "stop$(printf '\r')"

# Wait up to 20 seconds for server to close
StopChecks=0
while [[ $StopChecks -lt 20 ]]; do
  if ! $SCREEN_CMD -list | grep -q '\.servername\s'; then
    break
  fi
  sleep 1
  StopChecks=$((StopChecks + 1))
done

# Force quit if server is still open
if $SCREEN_CMD -list | grep -q '\.servername\s'; then
  echo "Minecraft server still hasn't stopped after 20 seconds, closing screen manually"
  $SCREEN_CMD -S servername -X quit
fi

echo "Minecraft server servername stopped."
