module Jekyll

  class Counter
    def self.get_value(array, idx, default)
      return default unless array

      if array.size == 1 && idx >= 1
        array[0]
      elsif idx > array.size - 1
        default
      else
        array[idx]
      end
    end

    def self.to_string(hash, format)
      hash.each do |key, value|
        hash[key] = to_f_s(value, format)
      end
    end

    def self.to_f_s(number, format)
      if number - number.round != 0
        format % number.to_s
      else
        format % number.round.to_s
      end
    end
  end

  DEFAULTS = {
    'unit' => '%s ¥',
    'collection' => 'collection',
    'time' => 'time',
    'category' => 'category',
    'type' => 'tag',
    'number' => 'number',
    'name' => 'name',
    'divide' => 'divide',
    'people' => 'people'
  }.freeze

  DATE_FILENAME_MATCHER = %r!^(?>.+/)*?(\d{2,4}-\d{1,2}-\d{1,2})(-([^/]*))?(\.[^.]+)$!.freeze

  Jekyll::Hooks.register :site, :after_init do |data|
    # 修改正则让2021-01-01.md无后缀可读
    Jekyll::Document::DATE_FILENAME_MATCHER = DATE_FILENAME_MATCHER
  end

  Jekyll::Hooks.register :site, :post_read do |site|

    CR = 'counter'.freeze
    YR = 'year'.freeze
    MO = 'month'.freeze
    DA = 'day'.freeze

    config = Utils.deep_merge_hashes(DEFAULTS, site.config.fetch(CR, {}))

    UNIT = config['unit'].freeze
    COLL = config['collection'].freeze
    TIME = config['time'].freeze
    CATE = config['category'].freeze
    TYPE = config['type'].freeze
    NUMB = config['number'].freeze
    NAME = config['name'].freeze
    DIVE = config['divide'].freeze
    PELE = config['people'].freeze

    def get_value(array, idx, default)
      if array.size == 1 && idx >= 1
        array[0]
      elsif idx > array.size - 1
        default
      else
        array[idx]
      end
    end

    posts = site.collections['posts'] # 文章集合
    docs = posts.docs # 文章里的文档
    new_docs = [] # 创建新的文档
    count = 0.0 # 累计计数
    y_all = {} # 年
    m_all = {} # 月
    d_all = {} # 日
    c_all = {} # 类型
    t_all = {} # 标签
    docs.each do |doc|
      date = doc.data.include?('date') ? doc.data['date'] : doc.basename_without_ext
      days = date.strftime('%Y/%m/%d')
      mont = date.strftime('%Y/%m')
      year = date.strftime('%Y')
      collections = doc.data[COLL]
      # 下一步 如果 books 有值 且 不为空
      next unless collections && !collections.empty?

      collections.each do |coll|

        coll.each do |key, value|
          case value
          when Numeric
            coll[key] = [value]
          when String
            coll[key] = value.split(', ')
          end
        end

        count = coll.max { |a, b| a.size <=> b.size }.size

        (0..count - 1).each do |idx|
          # 取需要的默认值
          cate = Counter.get_value(coll[CATE], idx, "no #{CATE}")
          type = Counter.get_value(coll[TYPE], idx, "no #{TYPE}")
          name = Counter.get_value(coll[NAME], idx, "no #{NAME}")
          numb = Counter.get_value(coll[NUMB], idx, '0')
          dive = Counter.get_value(coll[DIVE], idx, '1')
          pele = Counter.get_value(coll[PELE], idx, '1')
          # 可能会死循环
          new_doc = Document.new(doc.path, site: site, collection: posts)
          new_doc.data.replace(doc.data)
          # 初始化第一个数据
          c_all[cate] = 0.0 unless c_all.include?(cate)
          t_all[type] = 0.0 unless t_all.include?(type)
          d_all[days] = 0.0 unless d_all.include?(days)
          m_all[mont] = 0.0 unless m_all.include?(mont)
          y_all[year] = 0.0 unless y_all.include?(year)
          # 转为两位小数
          numb_to_f = numb.to_f.round(2)
          # 叠加
          c_all[cate] += numb_to_f
          t_all[type] += numb_to_f
          d_all[days] += numb_to_f
          m_all[mont] += numb_to_f
          y_all[year] += numb_to_f
          count += numb_to_f
          # 重新赋值
          new_doc.data[COLL] = coll
          new_doc.data['tags'] = [type]
          new_doc.data['categories'] = [cate]
          new_doc.data['title'] = Counter.to_f_s(numb_to_f, UNIT)
          new_doc.data['excerpt'] = name
          new_doc.data['permalink'] = "/:year/:month/:day/#{idx}/"
          new_docs << new_doc
        end
      end
    end
    Counter.to_string(c_all, UNIT)
    Counter.to_string(t_all, UNIT)
    Counter.to_string(d_all, UNIT)
    Counter.to_string(m_all, UNIT)
    Counter.to_string(y_all, UNIT)
    site.data[CR] = {
      YR => y_all,
      MO => m_all,
      DA => d_all,
      TYPE => t_all,
      CATE => c_all,
      CR => count
    }
    if new_docs.size != 0
      posts.docs = new_docs
    end
  end
end
