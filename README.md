# pubox

Next gen casual sport portal

## Stack
DB: Postgres/ Supabase
Frontend: Flutter
Complex operations are done at SQL functions and called using Supabase


## Flow
User will choose a "context sport" (frontend variable). The app will help them
find teammates, parties ("lobby"), organize play, hire coaches/ referees etc

4 Main Tabs:
- Home: split into 4 subtabs
    - Teammates: find people/ lobbies to play with
    - Challengers: put up your lobby for challengers or look for them
    - Neutrals: hire coaches, referees, etc for your sport
    - Locations: find available venues according to criteria
- Manage:
    - the user's schedule
    - their lobbies' activities: view, accept/ reject play invite, split bill, inspect history etc
- Health: integrate with user's wearables
    - capture data during activities
    - gamify and encourage further interactions (goals/ achievements etc)
- Profile:
    - general account bookkeeping
    - misc info/ preference on any particular sport: skill level, fitness level, play position
    - their consistent schedule for matchmaking
    - network and industry: allow user to choose from preset choices and improve matchmaking

## Coding Guidelines
- Database schema dumped in ./schema/
- Organize code by their screen
- If a feature involves multiple screens, make a folder in each screen
- Generic, omni-present features or models go into /core
- Avoid nesting, prefer a flat folder structure
- Use Riverpod for state management. Avoid using Provider
- App-level model is created with freezed. persisted in json form. app state persistence key is _stateKey (mostly for riverpod providers)
- If an entity has db id and its app model is enum, use the db value as the enum value
- Use JsonEnum whenever possible
- Use SharedPreferences to persist important app states
- Use Vietnamese for UI/ messages but do not translate jargon

## Internationalization
The app supports English and Vietnamese. Translations are stored in JSON files in the `assets/translations` directory


Make sure to keep the English industry names as keys exactly as they appear in the database and provide the Vietnamese translations as values.
