// 测试 Supabase 数据库连接的脚本
const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');
const path = require('path');

// 手动加载 .env.local 文件
const envPath = path.join(__dirname, '.env.local');
if (fs.existsSync(envPath)) {
  const envContent = fs.readFileSync(envPath, 'utf8');
  envContent.split('\n').forEach(line => {
    const [key, ...valueParts] = line.split('=');
    if (key && valueParts.length > 0) {
      const value = valueParts.join('=').trim();
      if (!process.env[key]) {
        process.env[key] = value;
      }
    }
  });
}

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseKey) {
  console.error('❌ 缺少 Supabase 环境变量');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey);

async function testDatabaseConnection() {
  console.log('🔍 开始检查 Supabase 数据库连接...\n');
  
  try {
    // 1. 测试基本连接
    console.log('1. 测试基本连接...');
    const { data, error } = await supabase.from('authors').select('count', { count: 'exact', head: true });
    
    if (error) {
      console.error('❌ 数据库连接失败:', error.message);
      return false;
    }
    
    console.log('✅ 数据库连接成功');
    
    // 2. 检查表是否存在
    console.log('\n2. 检查数据库表...');
    const tables = ['authors', 'tags', 'articles', 'comments', 'subscribers', 'contact_messages'];
    
    for (const table of tables) {
      try {
        const { error: tableError } = await supabase.from(table).select('*').limit(1);
        if (tableError) {
          console.log(`❌ 表 ${table} 不存在或无法访问:`, tableError.message);
        } else {
          console.log(`✅ 表 ${table} 存在且可访问`);
        }
      } catch (err) {
        console.log(`❌ 表 ${table} 检查失败:`, err.message);
      }
    }
    
    // 3. 检查数据
    console.log('\n3. 检查现有数据...');
    
    // 检查作者数据
    const { data: authorsData, error: authorsError } = await supabase
      .from('authors')
      .select('*');
    
    if (!authorsError) {
      console.log(`✅ 作者表有 ${authorsData.length} 条记录`);
    }
    
    // 检查标签数据
    const { data: tagsData, error: tagsError } = await supabase
      .from('tags')
      .select('*');
    
    if (!tagsError) {
      console.log(`✅ 标签表有 ${tagsData.length} 条记录`);
    }
    
    // 检查文章数据
    const { data: articlesData, error: articlesError } = await supabase
      .from('articles')
      .select('*');
    
    if (!articlesError) {
      console.log(`✅ 文章表有 ${articlesData.length} 条记录`);
    }
    
    console.log('\n🎉 数据库检查完成！');
    return true;
    
  } catch (error) {
    console.error('❌ 检查过程中发生错误:', error);
    return false;
  }
}

// 运行测试
testDatabaseConnection().then(success => {
  if (success) {
    console.log('\n✅ Supabase 数据库已正常工作！');
  } else {
    console.log('\n❌ Supabase 数据库存在问题，请检查配置和迁移。');
  }
  process.exit(success ? 0 : 1);
});