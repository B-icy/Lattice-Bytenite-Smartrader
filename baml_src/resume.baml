// Defining a data model.
class Resume {
  name string
  email string
  experience string[]
  skills string[]
}

// Create a function to extract the resume from a string.
function ExtractResume(resume: string) -> Resume {
  // Route through OpenRouter so the OPENROUTER_API_KEY from .env is used.
  client ResumeExtractionClient
  prompt #"
    Extract from this content:
    {{ resume }}

    {{ ctx.output_format }}
  "#
}

client ResumeExtractionClient {
  provider openai
  options {
    model "inception/mercury-coder"
    api_key env.OPENROUTER_API_KEY
    base_url "https://openrouter.ai/api/v1"
    temperature 0.2
    max_tokens 800
    default_headers {
      "HTTP-Referer" "https://localhost:3000"
      "X-Title" "BAML Resume Extraction"
    }
  }
}

// Test the function with a sample resume. Open the VSCode playground to run this.
test vaibhav_resume {
  functions [ExtractResume]
  args {
    resume #"
      Vaibhav Gupta
      vbv@boundaryml.com

      Experience:
      - Founder at BoundaryML
      - CV Engineer at Google
      - CV Engineer at Microsoft

      Skills:
      - Rust
      - C++
    "#
  }
}
