# nDjin

nDjin is generativeAI powered character and game asset creation platform that enables game
creators to open up new frontiers of depth and uniqueness by levergaing gamerunner and player
guided content creation.

What was a static NFT trapped in its collection can now exist in a natural feeling game world.

nDjin enables game designer to build worlds that their players are truly invested in and keep
coming back to.

## nDjin Model

In nDjin, all content comes from multiple sources, including sources generated in nDjin, text description, user hints, and additional content.

Game designers build up a mood boards to characterize their style and refine, 
creating archetypical characters that can serve as guideposts for user generation.
They define parametric asset transformation and evolution pipelines which can 
selectively expose assets in process for user guidance and content review.

nDjin provides open APIs that can be used to generate assets of any kind - 
2d, 3d, text, audio, video along with multiple backends connecting to the 
leading genAI platforms and models, including in-house models.

Assets are composed of weighted materia and elements that can be incorporated 
via different strategies. For instance a particular asset might start as an 
image of an NFT character, a textual description of the character, and elements
parsed from metadata associated with the NFT. 

### nDjin Pipelines

nDjin projects are made up of a set of end products - the assets that will be
created – and asset generation pipelines that move the asset through various
transformation steps, utilizing genai, filters – even human-in-the loop phases.

Projects can expose the assets generated in their project to other projects,
provided users have consented.

Example pipeline that relies on two projects to create a new version of a
character useful in a tower defense game SHADES AND SAVIORS

(UIL == User-in-loop):

* NDJIN IMPORT
  * Import NFT (user)
  * Generate Materia & Elements (auto)
  * Augment Descriptions and preview character (UIL)
  * Create canonical character (auto)
  
* SHADES AND SAVIORS
  * Import and select mood content to generate a style (game designer)
  * Translate NDJIN IMPORT result into mood (UIL)
  * Generate SHADE version, headshot and full body (UIL)
  * Generate SAVIOR version, headshot and full body (UIL)
  * Generate sprites (UIL)
  * Review (game runner)

## nDjin and IP

nDjin natively understand player owned digital assets (NFTs), allowing game designers to partner 
with specific collections and ensuring that generated assets are derived from appropriately licensed content

The nDjin platform readily integrates into the top game development engines on 
and offchain through an open-source and expandible asset exporter

# nDjin Launch

At launch nDjin will support generation through Stability.AI & Leonardo.AI and
publishing to Dojo, Unity, and Bevy