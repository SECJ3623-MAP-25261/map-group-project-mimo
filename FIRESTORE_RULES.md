# Firestore Security Rules

## How to Update Firestore Rules

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to **Firestore Database** → **Rules** tab
4. Replace the existing rules with the rules below
5. Click **Publish**

## Required Security Rules

Copy and paste these rules into your Firestore Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper function to check if user is authenticated
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Helper function to check if user owns the document
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    // Bookings Collection
    match /bookings/{bookingId} {
      // Allow read if user is the owner (userId) or the renter (renterId)
      allow read: if isAuthenticated() && 
        (resource.data.userId == request.auth.uid || 
         resource.data.renterId == request.auth.uid);
      
      // Allow create if user is authenticated and sets their own userId
      allow create: if isAuthenticated() && 
        request.resource.data.userId == request.auth.uid;
      
      // Allow update if user is the owner or renter
      allow update: if isAuthenticated() && 
        (resource.data.userId == request.auth.uid || 
         resource.data.renterId == request.auth.uid);
      
      // Allow delete if user is the owner
      allow delete: if isAuthenticated() && 
        resource.data.userId == request.auth.uid;
    }
    
    // Face Verifications Collection
    match /face_verifications/{verificationId} {
      // Allow read if user is authenticated
      allow read: if isAuthenticated();
      
      // Allow create if user is authenticated
      allow create: if isAuthenticated();
      
      // Allow update if user is authenticated
      allow update: if isAuthenticated();
    }
    
    // Items Collection (if you have one)
    match /items/{itemId} {
      // Allow read for authenticated users
      allow read: if isAuthenticated();
      
      // Allow write only if user is the owner
      allow write: if isAuthenticated() && 
        resource.data.renterId == request.auth.uid;
    }
    
    // Users Collection (if you have one)
    match /users/{userId} {
      // Allow read for authenticated users
      allow read: if isAuthenticated();
      
      // Allow write only if user is updating their own document
      allow write: if isOwner(userId);
    }
    
    // Default: Deny all other access
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

## Quick Test Rules (Development Only - NOT for Production)

If you want to test quickly, you can use these permissive rules (⚠️ **ONLY FOR DEVELOPMENT**):

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

⚠️ **WARNING**: The test rules above allow any authenticated user to read/write to ALL collections. This is NOT secure for production!

## After Updating Rules

1. Wait a few seconds for rules to propagate
2. Try creating a booking again
3. If it still fails, check the Firebase Console → Firestore → Rules for any syntax errors




