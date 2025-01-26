import { updateRosterFromNHL, syncGamesFromNHL, processCompletedGames } from './nhl';

// Function to run all automated tasks
async function runAutomatedTasks() {
  try {
    // Process completed games only
    // This is the only task we want running automatically
    const gamesProcessed = await processCompletedGames();
    if (!gamesProcessed) {
      console.warn('Warning: Failed to process completed games');
    }
    
    return true;
  } catch (error) {
    console.error('Error running automated tasks:', error);
    return false;
  }
}

// Initialize automated tasks
export function initializeAutomation() {
  // Run immediately on startup
  setTimeout(runAutomatedTasks, 5000); // Add small delay to ensure DB connection is ready
  
  // Then run every 5 minutes
  setInterval(runAutomatedTasks, 5 * 60 * 1000);
}