assert = require('assert')
fs = require "fs"
path = require "path"

{
  isAttributeExists
  isAttributeSetExists
  normalizeAttribute
  normalizeAttributeSet
  createAttribute
  createAttributeSet
  deleteAttribute
  deleteAttributeSet
} = require('../mag-api')


describe 'Attempt-1', () ->

  describe '#normalizeAttribute()', () ->
    it 'should normalize attribute', () ->
      data = JSON.parse(fs.readFileSync(path.resolve(__dirname, "../samples/sample-attribute.json"), "utf-8"))
      norm = normalizeAttribute(data)
      norm.options.forEach (opt) ->
        assert.ok(opt.value == undefined)
      assert.ok(norm.is_used_in_grid == undefined)
      assert.ok(norm.is_visible_in_grid == undefined)
      assert.ok(norm.is_filterable_in_grid == undefined)
      assert.ok(norm.apply_to == undefined)


  describe '#createAttribute() && deleteAttribute()', () ->
    it 'should create and delete attribute', (done) ->
      data = JSON.parse(fs.readFileSync(path.resolve(__dirname, "../samples/sample-attribute.json"), "utf-8"))
      norm = normalizeAttribute(data)
      createAttribute(norm)
        .then (attr) ->
          assert.ok(attr.message == undefined)
          assert.equal("embroidery_colour", attr.attribute_code)
          assert.ok(attr.options.length >= norm.options.length)
          deleteAttribute(attr.attribute_id).then (err) ->
            assert.ok(err == null)
            done()
          .catch (e) ->
            done(e)
        .catch (e) ->
          done(e)
      return

  describe '#createAttributeSet() && deleteAttributeSet()', () ->
    it 'should create attribute set', (done) ->
      data = JSON.parse(fs.readFileSync(path.resolve(__dirname, "../samples/sample-attribute-set.json"), "utf-8"))
      norm = normalizeAttributeSet(data)
      createAttributeSet(norm)
        .then (attrSet) ->
          assert.ok(attrSet.message == undefined)
          assert.equal("Eggs", attrSet.attribute_set_name)
          deleteAttributeSet(attrSet.attribute_set_id).then (err) ->
            assert.ok(err == null)
            done()
          .catch (e) ->
            done(e)
        .catch (e) ->
          done(e)
      return


  describe '#isAttributeExists()', () ->
    it 'should find attribute', (done) ->
      isAttributeExists('short_description')
        .then (attr) ->
          assert.notEqual(undefined, attr)
          assert.equal('short_description', attr.attribute_code)
          done()
        .catch (e) ->
          done(e)
      return
    it 'should not find attribute', (done) ->
      isAttributeExists('some_not_existing_attribute')
        .then (attr) ->
          assert.equal(undefined, attr)
          done()
        .catch (e) ->
          done(e)
      return


  describe '#isAttributeSetExists()', () ->
    it 'should find attribute', (done) ->
      isAttributeSetExists('Eggs')
        .then (attrSet) ->
          assert.notEqual(undefined, attrSet)
          assert.equal('Eggs', attrSet.attribute_set_name)
          done()
        .catch (e) ->
          done(e)
      return
    it 'should not find attribute', (done) ->
      isAttributeSetExists('SomeSet')
        .then (attrSet) ->
          assert.equal(undefined, attrSet)
          done()
        .catch (e) ->
          done(e)
      return