# Contributing

Thank you for interest in contributing to the event-driven choreography example!

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/gcp-pubsub-choreography.git`
3. Create a feature branch: `git checkout -b feature/your-feature-name`
4. Make your changes
5. Push to your fork
6. Submit a pull request

## Code Style

- **Python:** Follow [PEP 8](https://www.python.org/dev/peps/pep-0008/)
- **Terraform:** Use `terraform fmt` to format
- **Documentation:** Use Markdown with clear examples

## Testing

Before submitting a PR:
1. Run `terraform fmt` on Infrastructure code
2. Test locally if possible
3. Update documentation if you change functionality

## Reporting Issues

Found a bug or have a suggestion?
1. Check [existing issues](../../issues) first
2. If not found, [create a new issue](../../issues/new)
3. Include:
   - Clear description of the problem
   - Steps to reproduce (if bug)
   - Expected vs. actual behavior
   - Your environment (OS, GCP region, etc.)

## Security

⚠️ **NEVER commit:**
- GCP service account keys or credentials
- Terraform state files (*.tfstate)
- terraform.tfvars with real values
- SendGrid API keys or other secrets
- Real email addresses or personal data

If you accidentally commit secrets:
1. Rotate the exposed credentials immediately
2. Use [git-filter-branch](https://git-scm.com/docs/git-filter-branch) or [BFG Repo-Cleaner](https://rtyley.github.io/bfg-repo-cleaner/) to remove from history
3. Notify the maintainer

## Pull Request Process

1. Update README.md or ARCHITECTURE.md if you change functionality
2. Ensure .gitignore excludes sensitive files
3. Reference any related issues: "Closes #123"
4. Describe what your PR changes and why

## Questions?

- Ask in an issue (use the question label)
- Check ARCHITECTURE.md for how the system works
- Check GCP_ISSUES.md for common GCP problems

## License

By contributing, you agree your code will be licensed under the MIT License.
