# Skill installations and omissions for all AI agents.
# Imported by config/instructions.nix.

{
  skills = [
    # Repo-level installs (all skills from repo)
    "obra/superpowers"
    "anthropics/skills"
    "affaan-m/everything-claude-code"
    "alirezarezvani/claude-skills"
    "microsoft/playwright-cli"

    # Individual skills (--skill flag)
    {
      repo = "vercel-labs/skills";
      skill = "find-skills";
    }
    {
      repo = "vercel-labs/agent-skills";
      skill = "vercel-react-best-practices";
    }
    {
      repo = "affaan-m/everything-claude-code";
      skill = "backend-patterns";
    }
    {
      repo = "vercel-labs/agent-skills";
      skill = "vercel-composition-patterns";
    }
    {
      repo = "affaan-m/everything-claude-code";
      skill = "security-review";
    }
    {
      repo = "obra/superpowers";
      skill = "systematic-debugging";
    }
    {
      repo = "obra/superpowers";
      skill = "verification-before-completion";
    }
    {
      repo = "obra/superpowers";
      skill = "writing-plans";
    }
    {
      repo = "anthropics/skills";
      skill = "webapp-testing";
    }
    {
      repo = "vercel-labs/agent-skills";
      skill = "web-design-guidelines";
    }
    {
      repo = "remotion-dev/skills";
      skill = "remotion-best-practices";
    }
    {
      repo = "anthropics/skills";
      skill = "frontend-design";
    }
    {
      repo = "vercel-labs/agent-browser";
      skill = "agent-browser";
    }
  ];

  # Keep broad repo installs, then remove language/framework-specific skills.
  omitSkills = [
    # Language/framework-specific skills to omit.
    "django-patterns"
    "django-security"
    "django-tdd"
    "django-verification"
    "springboot-patterns"
    "springboot-security"
    "springboot-tdd"
    "springboot-verification"
    "java-coding-standards"
    "jpa-patterns"
    "kotlin-coroutines-flows"
    "kotlin-exposed-patterns"
    "kotlin-ktor-patterns"
    "kotlin-patterns"
    "kotlin-testing"
    "swift-actor-persistence"
    "swift-concurrency-6-2"
    "swift-protocol-di-testing"
    "swiftui-patterns"
    "perl-patterns"
    "perl-security"
    "perl-testing"
  ];
}
