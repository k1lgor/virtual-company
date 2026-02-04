---
name: skill-generator
description: Use this to help write, optimize, or debug other Virtual Company SKILL.md files.
---

# Skill Generator

You help the user create new skills for Virtual Company.

## When to use

- "Create a skill for..."
- "Optimize this SKILL.md."
- "Write a generic skill for Java development."

## Instructions

1. Requirement Gathering:
   - Ask what specific domain or task the skill should handle.
2. Structure:
   - Create a valid folder name (kebab-case).
   - Write the YAML frontmatter with a clear name and a concise, high-signal description.
3. Content:
   - Write instructions that are language/framework agnostic unless specified.
   - Include "When to use," "Instructions," and "Examples."
4. Safety:
   - Ensure the skill does not encourage destructive actions without confirmation.

## Examples

### 1. Complete Skill Example: GraphQL Specialist

```markdown
---
name: graphql-specialist
description: Use this for designing GraphQL schemas, implementing resolvers, optimizing queries, and handling subscriptions.
---

# GraphQL Specialist

You design and implement efficient GraphQL APIs with proper schema design and query optimization.

## When to use

- "Create a GraphQL schema for..."
- "Implement resolvers for this API."
- "Optimize this GraphQL query."
- "Add subscriptions for real-time updates."

## Instructions

1. Schema Design:
   - Define clear, self-documenting types and fields.
   - Use proper scalar types (ID, String, Int, Float, Boolean, custom scalars).
   - Implement interfaces for shared fields across types.
   - Use unions for polymorphic returns.

2. Resolvers:
   - Keep resolvers thin - delegate business logic to services.
   - Implement DataLoader to prevent N+1 query problems.
   - Handle errors gracefully with proper error types.

3. Query Optimization:
   - Limit query depth and complexity.
   - Implement field-level caching where appropriate.
   - Use persisted queries for production.

4. Security:
   - Implement authentication and authorization at the resolver level.
   - Validate and sanitize all inputs.
   - Rate limit expensive queries.

## Examples

### 1. Schema Definition

\`\`\`graphql
type User {
id: ID!
email: String!
name: String!
posts: [Post!]!
createdAt: DateTime!
}

type Post {
id: ID!
title: String!
content: String!
author: User!
published: Boolean!
tags: [String!]!
}

type Query {
user(id: ID!): User
users(limit: Int = 10, offset: Int = 0): [User!]!
post(id: ID!): Post
posts(authorId: ID, published: Boolean): [Post!]!
}

type Mutation {
createPost(input: CreatePostInput!): Post!
updatePost(id: ID!, input: UpdatePostInput!): Post!
deletePost(id: ID!): Boolean!
}

input CreatePostInput {
title: String!
content: String!
tags: [String!]
}
\`\`\`

### 2. Resolver with DataLoader

\`\`\`javascript
const DataLoader = require('dataloader');

// Batch function to load users
const batchUsers = async (userIds) => {
const users = await User.findAll({
where: { id: userIds }
});

// Return in same order as requested
return userIds.map(id =>
users.find(user => user.id === id)
);
};

const resolvers = {
Query: {
user: async (_, { id }, { loaders }) => {
return loaders.user.load(id);
},
users: async (_, { limit, offset }) => {
return User.findAll({ limit, offset });
}
},

Post: {
author: async (post, \_, { loaders }) => {
// Use DataLoader to batch requests
return loaders.user.load(post.authorId);
}
},

Mutation: {
createPost: async (\_, { input }, { user }) => {
if (!user) throw new Error('Not authenticated');

      return Post.create({
        ...input,
        authorId: user.id
      });
    }

}
};

// Context function
const context = ({ req }) => {
return {
user: req.user,
loaders: {
user: new DataLoader(batchUsers)
}
};
};
\`\`\`
```

### 2. Skill Template Structure

```markdown
---
name: [skill-name-in-kebab-case]
description: One-sentence description of when to use this skill (starts with "Use this for..." or "Use this when...").
---

# [Skill Display Name]

[One sentence describing what this skill does and the value it provides.]

## When to use

- "[Example user request 1]"
- "[Example user request 2]"
- "[Example user request 3]"
- "[Example user request 4]"

## Instructions

1. [First Major Step]:
   - [Specific guideline]
   - [Specific guideline]
   - [Specific guideline]

2. [Second Major Step]:
   - [Specific guideline]
   - [Specific guideline]

3. [Third Major Step]:
   - [Specific guideline]
   - [Specific guideline]

4. [Fourth Major Step]:
   - [Specific guideline]
   - [Specific guideline]

## Examples

### 1. [Example Title]

\`\`\`[language]
[Complete, runnable code example]
\`\`\`

### 2. [Example Title]

\`\`\`[language]
[Complete, runnable code example]
\`\`\`

### 3. [Example Title]

\`\`\`[language]
[Complete, runnable code example]
\`\`\`
```

### 3. Best Practices Checklist

When creating a new skill, ensure:

**Structure:**

- [ ] Valid YAML frontmatter with `name` and `description`
- [ ] Clear skill title (H1 heading)
- [ ] One-sentence value proposition
- [ ] "When to use" section with 3-5 examples
- [ ] "Instructions" section with 3-5 numbered steps
- [ ] "Examples" section with 2-4 code examples

**Content Quality:**

- [ ] Description is concise (under 150 characters)
- [ ] Instructions are actionable, not theoretical
- [ ] Examples are complete and runnable
- [ ] Code examples include comments
- [ ] Language/framework agnostic unless specified
- [ ] No destructive actions without warnings

**Naming:**

- [ ] Folder name uses kebab-case (e.g., `27-graphql-specialist`)
- [ ] Folder starts with number for ordering
- [ ] Skill name in frontmatter matches folder (without number)
- [ ] Display name is human-readable

**File Organization:**

```
.agent/skills/
└── 27-graphql-specialist/
    ├── SKILL.md          # Required: Main skill file
    ├── examples/         # Optional: Additional examples
    │   └── schema.graphql
    └── scripts/          # Optional: Helper scripts
        └── validate.js
```
