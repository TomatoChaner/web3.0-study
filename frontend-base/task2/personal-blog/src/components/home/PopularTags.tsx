import Link from 'next/link'

// 模拟数据，实际项目中会从 API 获取
const popularTags = [
  { id: '1', name: 'Next.js', slug: 'nextjs', color: '#000000', article_count: 15 },
  { id: '2', name: 'React', slug: 'react', color: '#61DAFB', article_count: 23 },
  { id: '3', name: 'TypeScript', slug: 'typescript', color: '#3178C6', article_count: 18 },
  { id: '4', name: '前端开发', slug: 'frontend', color: '#FF6B6B', article_count: 32 },
  { id: '5', name: 'Supabase', slug: 'supabase', color: '#3ECF8E', article_count: 8 },
  { id: '6', name: '全栈开发', slug: 'fullstack', color: '#8B5CF6', article_count: 12 },
  { id: '7', name: 'JavaScript', slug: 'javascript', color: '#F7DF1E', article_count: 28 },
  { id: '8', name: 'CSS', slug: 'css', color: '#1572B6', article_count: 16 },
  { id: '9', name: 'Node.js', slug: 'nodejs', color: '#339933', article_count: 14 },
  { id: '10', name: 'Web开发', slug: 'web-development', color: '#FF4081', article_count: 25 },
]

export function PopularTags() {
  return (
    <div className="flex flex-wrap gap-3 justify-center">
      {popularTags.map((tag) => (
        <Link
          key={tag.id}
          href={`/tags/${tag.slug}`}
          className="group relative inline-flex items-center px-4 py-2 rounded-full text-sm font-medium transition-all duration-200 hover:scale-105"
          style={{
            backgroundColor: `${tag.color}15`,
            color: tag.color,
            border: `1px solid ${tag.color}30`,
          }}
        >
          <span className="relative z-10">{tag.name}</span>
          <span className="ml-2 text-xs opacity-75">({tag.article_count})</span>
          
          {/* Hover effect */}
          <div
            className="absolute inset-0 rounded-full opacity-0 group-hover:opacity-20 transition-opacity duration-200"
            style={{ backgroundColor: tag.color }}
          />
        </Link>
      ))}
    </div>
  )
}