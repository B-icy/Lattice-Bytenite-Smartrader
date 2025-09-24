import asyncio
from report_generator import ReportGenerator


async def main():
    """Main entry point for the stock analysis report generation system."""
    generator = ReportGenerator()
    await generator.generate_all_reports()


if __name__ == '__main__':
    asyncio.run(main())
