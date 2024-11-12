const express = require('express');
const app = express();
const PORT = 3000;

app.set('view engine', 'ejs');
require('dotenv').config();



const passport = require('passport');
const GitHubStrategy = require('passport-github').Strategy;
const GoogleStrategy = require('passport-google-oauth20').Strategy;


passport.use(new GoogleStrategy({
        clientID: process.env.GOOGLE_CLIENT_ID,
        clientSecret: process.env.GOOGLE_CLIENT_SECRET,
        callbackURL: 'http://localhost:3000/auth/google/callback'},
    function(accessToken, refreshToken, profile, cb) {
        cb(null, profile);
    }
));
passport.use(new GitHubStrategy({
  clientID: process.env.GITHUB_CLIENT_ID, // Replace with your GitHub Client ID
  clientSecret: process.env.GITHUB_CLIENT_SECRET, // Replace with your GitHub Client Secret
  callbackURL: "http://localhost:3000/auth/github/callback"
},
(accessToken, refreshToken, profile, done) => {
  // This is where you could save the user profile to your database
  return done(null, profile);
}));

// Serialize user information for session persistence
passport.serializeUser((user, done) => done(null, user));
passport.deserializeUser((user, done) => done(null, user));

const session = require('express-session');

app.use(session({ secret: 'yourSecretKey', resave: false, saveUninitialized: true }));
app.use(passport.initialize());
app.use(passport.session());





//Landing page
app.get('/', (req, res) => {
    res.render('home');
  });

// Serve a simple "login" page
app.get('/login', (req, res) => {
    res.render('login');
  });

app.get('/profile', (req, res) => {
    if (!req.isAuthenticated()) {
      return res.redirect('/login');
    }
    if(req.user.displayName){
        return res.render('profile', { username: req.user.displayName });
    }
    res.render('profile', { username: req.user.username });
  });

  app.get('/logout', (req, res) => {
    req.logout(() => {
      res.redirect('/');
    });
  });
  
  // Route to initiate GitHub authentication
app.get('/auth/github', passport.authenticate('github'));

// GitHub callback URL
app.get('/auth/github/callback', 
  passport.authenticate('github', { failureRedirect: '/login' }),
  (req, res) => {
    // Redirect to the profile page upon successful login
    res.redirect('/profile');
  });

// Route to initiate Google authentication
app.get('/auth/google', passport.authenticate('google', { scope: ['https://www.googleapis.com/auth/userinfo.profile', 'https://www.googleapis.com/auth/userinfo.email'] }));

// Google callback URL
app.get('/auth/google/callback',
    passport.authenticate('google', { failureRedirect: '/login' }),
    (req, res) => {
        // Redirect to the profile page upon successful login
        res.redirect('/profile');
    }
);

  // Projects page
app.get('/projects', (req, res) => {
    res.render('projects');
  });
  
  // GitHub Contributor Calendar page
  app.get('/github-calendar', (req, res) => {
    if (!req.isAuthenticated()) {
      return res.redirect('/login');
    }
    res.render('github-calendar', { username: req.user.username });
  });

// Start the server
app.listen(PORT, () => {
  console.log(`Server is running on http://localhost:${PORT}`);
});
